clear; close all;
cc = tamu_color();
cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
wavg_MD = @(we_inch, stdd_for_k) 0.56 .* erf(0.8 * stdd_for_k) .* we_inch .^ (0.83);
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
lambdax = [1.0, 2.0, 4.0, 6.0];
lambday = [1.0]; % must be only one number to fit all plots in figuress.
stdev = [0.025, 0.05, 0.075, 0.1];
file_name = 'cond.json';
colored_by = 'stdev';
sized_by = '';

n1 = numel(lambdax);
n2 = numel(lambday);
n3 = numel(stdev);
search_conditions = [reshape(repmat(lambdax, n2*n3, 1),1,[]); ...
    reshape(repmat(lambday, n3, n1),1,[]); ...
    reshape(repmat(stdev, n1*n2, 1).',1,[])];


%% prep figures
ax_cdc = create_tiledlayout(n3, n1);
ax_avg_cdc = create_tiledlayout(n3, n1);
ax_hist = create_tiledlayout(n3, n1);
ax_wavg_vs_cond = create_tiledlayout(n3, n1);
ax_we_vs_cond = create_tiledlayout(n3, n1);
ax_wavg_vs_kfw0 = create_tiledlayout(4, 1);
ax_wide_vs_wavg = create_tiledlayout(1, 4);
ax_temp = create_tiledlayout(1, 1);

%% param display names
pc_name = 'P_{c} [psi]';
cond_name = 'k_{f}w [md-ft]';
cond0_name = '(k_{f}w)_{0} [md-ft]';
we_name = 'w_{e} [in]';
wa_name = 'w_{avg} [in]';

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
    ilam = find(lambdax == lamx);
    istv = find(stdev == sdv);
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
        minline = max(mean_cdc - stdv_cdc, 0.1);
        fill(ax_avg_cdc(j), [pc, fliplr(pc)], [mean_cdc + stdv_cdc, fliplr(minline)], cc(5,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        hold(ax_avg_cdc(j), 'on')
        plot(ax_avg_cdc(j), pc, mean_cdc, '-', 'Color', cc(5, :), 'LineWidth', 1.5);
        hold(ax_avg_cdc(j), 'on')

        % FIGURE3: Histogram plot
        for i = 2:5
            h = histogram(ax_temp, cond_simu(:, i), 'BinWidth', 100);
            plot(ax_hist(j), h.BinEdges(1:end-1) + 0.5 .* diff(h.BinEdges), h.Values, 'o-', 'DisplayName', [num2str(pc(i)), ' psi'], 'Color', cc(i, :), 'MarkerFaceColor', cc(i, :));
            hold(ax_hist(j),'on');
        end
        title(ax_hist(j), search_condition);
        hold(ax_hist(j),'off');


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
end

close(ancestor(ax_temp, 'figure'))