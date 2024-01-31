clear; close all;
cc = tamu_color();
cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
lambdax = [1.0, 2.0, 4.0, 6.0];
lambday = [1.0]; % must be only one number to fit all plots in figuress.
stdev = [0.025, 0.05, 0.075, 0.1];
file_name = 'cond.json';
colored_by = 'lambda_x__in';
sized_by = 'wid_e__in';

n1 = numel(lambdax);
n2 = numel(lambday);
n3 = numel(stdev);
search_conditions = [reshape(repmat(lambdax, n2*n3, 1),1,[]); ...
    reshape(repmat(lambday, n3, n1),1,[]); ...
    reshape(repmat(stdev, n1*n2, 1).',1,[])];


%% prep figures
ax_cdc = create_tiledlayout(n1, n3);
ax_avg_cdc = create_tiledlayout(n1, n3);
ax_hist = create_tiledlayout(n1, n3);
ax_wavg_vs_cond = create_tiledlayout(n1, n3);
ax_wide_vs_wavg = create_tiledlayout(n1, n3);

%% prep experimental data
cond_exp_all = struct();
[cond_exp_all, ~] = add_exp_data(cond_exp_all, 'cond.json');

%% main program
err_cases = ["folder_name", 0];
ana = struct();
for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, 'all');

    % if color by search conditions, assign the color code here
    if isnumeric(colored_by) || colored_by == "search_conditions"
        colored_by = cc(mod(j, size(cc, 1)) + 1, :) + floor(j / size(cc, 1)) * 10 /255; % make them darker and darker once used first 9 colors
    end

    dataStruct = struct();

    for i = 1 : length(cases_meet_conditions)
        [dataStruct, err_flag] = store_batch_json(dataStruct, 'cond.json', cases_meet_conditions(i));
        if err_flag > 1
            err_cases = [err_cases; cases_meet_conditions(i), err_flag];
        end
    end



    search_condition = ['lambda', sprintf('%.1f', lamx), '-' , sprintf('%.1f', lamy), '-stdev', num2str(sdv)];
    if isempty(fieldnames(dataStruct))
        disp(['no data with the condition: ', search_condition]);
    else % if there's something in dataStruct, add plot on axes
        [cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft', colored_by, sized_by);
        % first calc representative values
        % mean
        mean_cdc = nan(1, 5);
        stdv_cdc = nan(1, 5);
        % median_cdc = nan(1, 5);
        % mode_cdc = nan(1, 5);
        for i=1:5
            cond_at_pc = cond_simu(:, i);
            mean_cdc(i)  = mean(cond_simu(:, i));
            stdv_cdc(i) = std(cond_simu(:, i));
            
            % median_cdc(i)  = median(cond_at_pc(~isnan(cond_at_pc) & ~isinf(cond_at_pc)));
            % mode_cdc(i)  = mode(cond_at_pc(~isnan(cond_at_pc) & ~isinf(cond_at_pc)));
        end

        % FIGURE1: cdc plot
        ax_cdc(j) = my_scatter(ax_cdc(j), 'line', [search_condition, 'n = ', num2str(numel(fields(dataStruct)))],...
            repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
            cond_simu, 'Conductivity [md-ft]', 'normal', ...
            marker_sizes, cc(4,:), disp_names);
        hold(ax_cdc(j), 'on')
        plot(ax_cdc(j), pc, mean_cdc, 'k-');
        plot(ax_cdc(j), pc, mean_cdc + stdv_cdc, pc, mean_cdc - stdv_cdc, '-', 'Color', cc(2, :));


        % FIGURE2: box plot
        % first draw representative values
        hold(ax_avg_cdc(j), 'on')
        fill(ax_avg_cdc(j), [pc, fliplr(pc)], [mean_cdc + stdv_cdc, fliplr(mean_cdc - stdv_cdc)], cc(2, :), 'FaceAlpha', 0.6);
        plot(ax_avg_cdc(j), pc, mean_cdc, '-', 'Color', cc(2, :));
        % median - don't use them since mean works good enough
        % plot(ax_avg_cdc(j), pc, median_cdc, '-', 'Color', cc(3, :));
        % % mode
        % plot(ax_avg_cdc(j), pc, mode_cdc, '-', 'Color', cc(4, :));d

        % ax_avg_cdc(j) = my_scatter(ax_avg_cdc(j), 'box', search_condition,...
        %     repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
        %     cond_simu, 'Conductivity [md-ft]', 'normal', ...
        %     marker_sizes, cc(4,:), disp_names);
        hold(ax_avg_cdc(j), 'off')
        % FIGURE3: Histogram plot
        for i = 2:5
            h = histogram(cond_simu(:, i), 'BinWidth', 100);
            plot(ax_hist(j), h.BinEdges(1:end-1) + 0.5 .* diff(h.BinEdges), h.Values, 'o-', 'DisplayName', [num2str(pc(i)), ' psi'], 'Color', cc(i, :), 'MarkerFaceColor', cc(i, :));
            hold(ax_hist(j),'on');
        end
        title(ax_hist(j), search_condition);
        hold(ax_hist(j),'off');

        % FIGURE4: Etched vs average width plot
        [wid_e, wid_a, marker_sizes, colors, disp_names] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in', colored_by, sized_by);

        field_name = strrep(['lam', num2str(lamx), '_', num2str(lamy), '_', num2str(sdv)], '.', '_');
        ana.(field_name).lamx = lamx;
        ana.(field_name).lamy = lamy;
        ana.(field_name).stdev = sdv;
        ps = zeros(numel(pc),2);
        for i = 1:numel(pc)
            ax_wavg_vs_cond(j) = my_scatter(ax_wavg_vs_cond(j), 'scatter', search_condition,...
                wid_a', 'Avg width [in]', 'log', ...
                cond_simu(:,i)', 'Conductivity [md-ft]', 'log', ...
                marker_sizes(1), cc(i,:), sprintf("P_c = %i psi",pc(i)));
            hold(ax_wavg_vs_cond(j),'on');
            % linear fit on log-log plot
            idx_both_positive = (wid_a > 0) & cond_simu(:, i) > 0;
            ps(i, :) = polyfit(log(wid_a(idx_both_positive)'), log(cond_simu(idx_both_positive,i)'), 1);
            fplot(ax_wavg_vs_cond(j), @(x) exp(ps(i, 2) + ps(i, 1) .* log(x)), '-', 'Color', cc(i,:), 'DisplayName', sprintf("P_c = %i psi",pc(i)))
        end

        ana.(field_name).p_slope = ps(:,1);
        ana.(field_name).p_interp = ps(:,2);


        ax_wide_vs_wavg(j) = my_scatter(ax_wide_vs_wavg(j), 'plot', search_condition,...
            wid_e, 'Etched width [in]', 'log', ...
            wid_a, 'Avg width [in]', 'log', ...
            marker_sizes, colors, disp_names);

        % linear fit on log-log plot
        idx_both_positive = (wid_a > 0) & (wid_e > 0);
        p2 = polyfit(log(wid_e(idx_both_positive)'), log(wid_a(idx_both_positive)'),1);
        ana.(field_name).p2 = p2';
        hold(ax_wide_vs_wavg(j),'on');
        fplot(ax_wide_vs_wavg(j), @(x) exp(p2(2) + p2(1) .* log(x)), 'k-');
        hold(ax_wide_vs_wavg(j),'off');
        % disp(p2);

        %% add exp data
        for b = fields(cond_exp_all)
            if cond_exp_all.(b{:}).lambda_x__in == lamx && cond_exp_all.(b{:}).lambda_y__in == lamy && cond_exp_all.(b{:}).stdev == sdv
                plot(ax_cdc(j), cond_exp_all.(b{:}).pc, cond_exp_all.(b{:}).cond);
            end
        end
    end

    if err_flag > 0
        err_cases = [err_cases; cases_meet_conditions(i), err_flag];
    end
end

% show the list of destination with error
disp('Error 2: cond.json exist but no pc_field recorded. run cond calculation again.')
err_cases(err_cases(:, 2) == "2", 1)
disp('Error 3: cond.json does not exist.')
err_cases(err_cases(:, 1) == "3", 1)
disp('Error 4: most likely averge width is negative.')
err_cases(err_cases(:, 1) == "3", 1)
disp('Error 5: most likely negative etched width.')
err_cases(err_cases(:, 1) == "5", 1)
disp('Error 6: conductivity is not decreasing with pc.')
err_cases(err_cases(:, 1) == "6", 1)

jsonText = jsonencode(ana, 'PrettyPrint', true);
% Write the JSON-formatted text to a file
fid = fopen('ana.json', 'w');
if fid == -1, error('Cannot create JSON file'); end
fwrite(fid, jsonText, 'char');
fclose(fid);

%% plot formatting
% FIGURE1: cdc plot

%ax_cdc(i).YLim = [10, 100000];
set(ax_cdc, 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off', 'LineWidth', 1.25);

for i = 1:size(search_conditions, 2)
    ax_cdc(i).XLim = [0, 4000];
    % FIGURE2: box plot
    ax_avg_cdc(i).XLim = [0, 4000];
    %ax_avg_cdc(i).YLim = [10, 100000];
    set(ax_avg_cdc(i), 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
    % FIGURE3: Histogram plot
    ax_hist(i).XLim = [0, 3000];
    colororder(ax_hist(i), cc)
    % FIGURE4: Etched vs average width plot
    % adding cubic law
    ax_wavg_vs_cond(i).XLim = [0.002, 0.05];
    %ax_wavg_vs_cond(i).YLim = [10, 100000];
    %xlim_from_datapts = ax_wavg_vs_cond(i).XLim;
    hold(ax_wavg_vs_cond(i),'on');
    plot(ax_wavg_vs_cond(i), ax_wavg_vs_cond(i).XLim, cubic_law_mdft(ax_wavg_vs_cond(i).XLim), 'k-', 'DisplayName','Cubic law');
    set(ax_wavg_vs_cond(i), 'XScale', 'log', 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');

    % FIGURE5
    ax_wide_vs_wavg(i).XLim = [0.07,  0.134];
    ax_wide_vs_wavg(i).YLim = [0.002, 0.05];
    set(ax_wavg_vs_cond(i), 'XScale', 'log', 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');

end
