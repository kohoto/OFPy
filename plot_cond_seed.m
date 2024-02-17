clear; close all;
cc = tamu_color();
lbl = my_labels();
lims = my_lims();
lamx_title = @(lamx) ['$\lambda_{x} = ', num2str(lamx), ' [in]$'];

cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
wavg_MD = @(we_inch, stdd_for_k) 0.56 .* erf(0.8 * stdd_for_k) .* we_inch .^ (0.83);
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
time_mode = 'all'; % or 'all' % do you wanna include conductivities from other etching time cases?
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
ax_lamx_we = create_tiledlayout(2, 2, 0.5);
ax_lamx_wa = create_tiledlayout(2, 2, 0.5);
ax_cdc = create_tiledlayout(n3, n1, 1);
ax_avg_cdc = create_tiledlayout(n3, n1, 1);
%figs = {create_tiledlayout(1, 4, 1), create_tiledlayout(1, 4, 1), create_tiledlayout(1, 4, 1), create_tiledlayout(1, 4, 1), create_tiledlayout(1, 4, 1)};
ax_C2_we = create_tiledlayout(4, 1, 1);
ax_hist = create_tiledlayout(n3, n1, 1);
ax_wavg_vs_cond = create_tiledlayout(n3, n1, 1);
ax_we_vs_cond = create_tiledlayout(n3, n1, 1);
ax_wavg_vs_kfw0 = create_tiledlayout(4, 1, 1);
ax_wide_vs_wavg = create_tiledlayout(2, 2, 0.5);
ax_temp = create_tiledlayout(1, 1, 0.5);

% allocation
n = zeros(n3, n1);
%% prep experimental data
cond_exp_all = struct();
[cond_exp_all, ~] = add_exp_data(cond_exp_all, 'cond.json');

%% main program
err_cases = ["folder_name", 0];
ana = struct();
cdc = struct(); % conductivity decline curve
for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, time_mode);
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
    indiv_title = [string(['$\lambda_{x} = ', num2str(lamx), ', \lambda_{y} = 1$']); string(['$\sigma = ', num2str(sdv), '$'])];
    if isempty(fieldnames(dataStruct))
        disp(['no data with the condition: ', search_condition]);
    else % if there's something in dataStruct, add plot on axes
        % read data into matrix
        field_name = strrep(['lam', num2str(lamx), '_', num2str(lamy), '_', num2str(sdv)], '.', '_');
        [wid_e, wid_a0, ~, ~, ~] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in', colored_by, sized_by);
        [cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft', colored_by, sized_by);
        [wid_a, ~, ~, ~, ~] = store_cond_var_from_struct(dataStruct, 'avg_w__in', colored_by, sized_by);
        n(ilam, istv) = numel(wid_e);


        % first calc representative values
        mean_cdc = nan(1, 5);
        stdv_cdc = nan(1, 5);
        p10_cdc = nan(1, 5);
        p90_cdc = nan(1, 5);
        for i=1:5
            cond_at_pc = cond_simu(:, i);
            mean_cdc(i)  = mean(cond_simu(:, i));
            stdv_cdc(i) = std(cond_simu(:, i));
            p10_cdc(i) = quantile(cond_simu(:, i), 0.1);
            p90_cdc(i) = quantile(cond_simu(:, i), 0.9);
        end

        % FIGURE1: stdev vs we plot
        hold(ax_lamx_we(istv), 'on')
        ax_lamx_we(istv) = my_scatter(ax_lamx_we(istv), 'scatter', [lbl.sdv, ' = ', num2str(sdv)],...
            lamx, lbl.lamx, 'normal', ...
            wid_e', lbl.we, 'normal', ...
            20, cc(5-istv,:), num2str(sdv));
        hold(ax_lamx_we(istv), 'off')
        % FIGURE2: stdev vs wa plot
        hold(ax_lamx_wa(istv), 'on')
        ax_lamx_wa(istv) = my_scatter(ax_lamx_wa(istv), 'scatter', [lbl.sdv, ' = ', num2str(sdv)],...
            lamx, lbl.lamx, 'normal', ...
            wid_a0', lbl.wa, 'normal', ...
            20, cc(5-istv,:), num2str(sdv));
        hold(ax_lamx_wa(istv), 'off')

        % FIGURE3: cdc plot
        hold(ax_cdc(ilam, istv), 'on')
        ax_cdc(ilam, istv) = my_scatter(ax_cdc(ilam, istv), 'alphaline', indiv_title,...
            repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
            cond_simu, 'Conductivity [md-ft]', 'normal', ...
            marker_sizes, cc(4,:), disp_names);
        hold(ax_cdc(ilam, istv), 'on')
        plot(ax_cdc(ilam, istv), pc, mean_cdc, '-', 'Color', cc(1, :), 'LineWidth', 1.5);
        hold(ax_cdc(ilam, istv), 'off')
        % get C1 and C2 for each plot!
        % CDC params (C1, C2) for each lines % "each" should be in CDC params (C1, C2) for each lines
        p_cdc_each = nan(size(cond_simu, 1), 2);
        for idata = 1:size(cond_simu, 1)
            p_cdc_each(idata, :) = polyfit(pc(2:end)', log(cond_simu(idata, 2:end)'), 1);
        end


        %% FIGURE XX: Dependency of the intercept on ideal width
        hold(ax_C2_we(ilam), 'on');
        ax_C2_we(ilam) = my_scatter(ax_C2_we(ilam), 'scatter', lamx_title(lamx),...
            wid_e', 'we', 'normal', ...
            p_cdc_each(:, 2)', 'C2', 'normal', ...
            20, cc(istv,:), sprintf("stdev = %f",sdv));
        hold(ax_C2_we(ilam), 'off');

        if time_mode =="600"
            % Overall C1 and C2 for each search conditions
            p_cdc = polyfit(pc(2:end)', log(mean_cdc(2:end)'), 1);
            hold(ax_cdc(ilam, istv), 'on')
            fplot(ax_cdc(ilam, istv), @(x) exp(p_cdc(2) + p_cdc(1) .* x), '--', 'Color', cc(end-6+i,:), 'DisplayName', '', 'LineWidth', 2.0);
            % save in struct
            cdc.(field_name).p_cdc = [p_cdc(1), exp(p_cdc(2))];
            cdc.(field_name).p_cdc_each = [p_cdc_each(:,1), exp(p_cdc_each(:,2))];
        end
        % plot(ax_cdc(ilam, istv), pc, mean_cdc - stdv_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        % plot(ax_cdc(ilam, istv), pc, mean_cdc + stdv_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        hold(ax_cdc(ilam, istv), 'on')
        plot(ax_cdc(ilam, istv), pc, p90_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        plot(ax_cdc(ilam, istv), pc, p10_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        hold(ax_cdc(ilam, istv), 'off')

        % FIGURE4: stdev band plot
        % first draw representae3tive values
        minline = max(mean_cdc - stdv_cdc, 0.1);
        % fill(ax_avg_cdc(ilam, istv), [pc, fliplr(pc)], [mean_cdc + stdv_cdc, fliplr(minline)], cc(1,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        hold(ax_avg_cdc(ilam, istv), 'on')
        fill(ax_avg_cdc(ilam, istv), [pc, fliplr(pc)], [p10_cdc, fliplr(p90_cdc)], cc(1,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        hold(ax_avg_cdc(ilam, istv), 'on')
        plot(ax_avg_cdc(ilam, istv), pc, mean_cdc, '-', 'Color', cc(1, :), 'LineWidth', 1.5);
        hold(ax_avg_cdc(ilam, istv), 'off')

        % FIGURE5: Histogram plot
        xs = nan(size(cond_simu))';
        ys = nan(size(cond_simu))';
        for i = 1:5
            binwidth = 100;
            h = histogram(ax_temp, cond_simu(:, i), 'BinWidth', binwidth);
            xs(i, 1:h.NumBins) = h.BinEdges(1:end-1) + 0.5 .* diff(h.BinEdges);
            ys(i, 1:h.NumBins) = h.Values;
        end
        ax_hist(ilam, istv) = my_scatter(ax_hist(ilam, istv), 'alphaline', indiv_title,...
            xs(1,:), 'Conductivity [md-ft]', 'normal', ...
            ys(1,:), 'Counts', 'normal', ...
            12, cc(1,:), '');

        %% FIGURE7: Value ranges plot ax by lambda, color by stdev
        % disable it cause it takes time
        % for ipc = 1:5
        %     hold(figs{ipc}(ilam), 'on');
        %     boxplot(figs{ipc}(ilam), cond_simu(:, ipc)', 'Positions', istv, 'Widths', 0.5, 'Color', cc(5-istv, :), 'BoxStyle', 'filled', 'Symbol', ".");
        %     hold(figs{ipc}(ilam), 'off');
        % end

        %% FIGURE8: Avged vs conductivity plot
        if time_mode == "all"
            ana.(field_name).lamx = lamx;
            ana.(field_name).lamy = lamy;
            ana.(field_name).stdev = sdv;
        else
            cdc.(field_name).lamx = lamx;
            cdc.(field_name).lamy = lamy;
            cdc.(field_name).stdev = sdv;
        end

        ps = zeros(numel(pc),2);
        p_cdc = zeros(1,2);
        p_beta = zeros(1,2);
        for i = 1:numel(pc)
            % linear fit on log-log plot
            hold(ax_wavg_vs_cond(ilam, istv), 'on');
            idx_both_positive = (wid_a(:, i) > 0) & cond_simu(:, i) > 0;
            ps(i, :) = polyfit(log(wid_a(idx_both_positive,i)'), log(cond_simu(idx_both_positive,i)'), 1);
            fplot(ax_wavg_vs_cond(ilam, istv), @(x) exp(ps(i, 2) + ps(i, 1) .* log(x)), '-', 'Color', cc(end-6+i,:), 'DisplayName', '');
            hold(ax_wavg_vs_cond(ilam, istv), 'on');

            % plot simulation data
            ax_wavg_vs_cond(ilam, istv) = my_scatter(ax_wavg_vs_cond(ilam, istv), 'scatter', indiv_title,...
                wid_a(:,i)', 'Avg width [in]', 'log', ...
                cond_simu(:,i)', 'Conductivity [md-ft]', 'log', ...
                7, cc(end-6+i,:), sprintf("P_c = %i psi",pc(i)));
            hold(ax_wavg_vs_cond(ilam, istv), 'off');
            ax_wavg_vs_cond(ilam, istv).XLim = [min(wid_a(:,i)), max(wid_a(:,i))];
        end
        % linear fit with all pc data
        hold(ax_wavg_vs_cond(ilam, istv), 'on');
        idx_both_positive = (wid_a(:) > 0) & cond_simu(:) > 0;

        x = wid_a(idx_both_positive);
        y = cond_simu(idx_both_positive);
        p_beta = polyfit(log(x'), log(y'), 1);
        fplot(ax_wavg_vs_cond(ilam, istv), @(x) exp(p_beta(2) + p_beta(1) .* log(x)), '--', 'Color', 'k', 'DisplayName', '');
        hold(ax_wavg_vs_cond(ilam, istv), 'on');

        if time_mode =="all"
            % update slope values
            ana.(field_name).ps_slope = ps(:,1);
            ana.(field_name).ps_interp = exp(ps(:,2));

            ana.(field_name).p_beta = p_beta(1);
            ana.(field_name).p_alpha = exp(p_beta(2));
        end

        %% FIGURE9: Etched vs average width plot
        pe = zeros(numel(pc),2);
        for i = 1:numel(pc)
            % linear fit on log-log plot
            hold(ax_we_vs_cond(ilam, istv), 'on');
            idx_both_positive = (wid_e > 0) & cond_simu(:, i) > 0;
            pe(i, :) = polyfit(log(wid_e(idx_both_positive)'), log(cond_simu(idx_both_positive,i)'), 1);
            fplot(ax_we_vs_cond(ilam, istv), @(x) exp(pe(i, 2) + pe(i, 1) .* log(x)), '-', 'Color', cc(end-6+i,:), 'DisplayName', '', 'LineWidth', 1.0)
            % plot simulation data
            hold(ax_we_vs_cond(ilam, istv), 'on');
            ax_we_vs_cond(ilam, istv) = my_scatter(ax_we_vs_cond(ilam, istv), 'scatter', indiv_title,...
                wid_e', lbl.we, 'log', ...
                cond_simu(:,i)', 'Conductivity [md-ft]', 'log', ...
                marker_sizes(1), cc(end-6+i,:), sprintf("P_c = %i psi",pc(i)));
            ax_we_vs_cond(ilam, istv).XLim = [min(wid_e), max(wid_e)];
        end
        if time_mode =="all"
            % save slope and intercept for slope analysis
            ana.(field_name).pe_slope = pe(:,1);
            ana.(field_name).pe_interp = exp(pe(:,2));
        end


        %% FIGURE10 wavg vs kfw0
        hold(ax_wavg_vs_kfw0(ilam), 'on');
        ax_wavg_vs_kfw0(ilam).XLim = [...
            min([wid_a0; ax_wavg_vs_kfw0(ilam).XLim(1)]), ...
            max([wid_a0; ax_wavg_vs_kfw0(ilam).XLim(2)])];
        fplot(ax_wavg_vs_kfw0(ilam), @(x) exp(ps(1, 2) + ps(1, 1) .* log(x)), '-', 'Color', cc(istv,:), 'DisplayName', '', 'LineWidth', 1.0);

        % plot simulation data
        hold(ax_wavg_vs_kfw0(ilam), 'on');
        ax_wavg_vs_kfw0(ilam) = my_scatter(ax_wavg_vs_kfw0(ilam), 'scatter', lamx_title(lamx),...
            wid_a0', lbl.wa, 'log', ...
            cond_simu(:,1)', lbl.kfw0_short, 'log', ...
            12, cc(istv,:), sprintf("stdev = %.3f",sdv));
        % add number of data - don't add since they'll be overlapped
        %ax_wavg_vs_kfw0(ilam) = add_ndata_on_plot(ax_wavg_vs_kfw0(ilam), numel(wid_a0), 0.004, 500);

        %% FIGURE11 we vs wavg
        % linear fit on log-log plot
        idx_both_positive = (wid_a0 > 0) & (wid_e > 0);
        p2 = polyfit(log(wid_e(idx_both_positive)'), log(wid_a0(idx_both_positive)'),1);
        hold(ax_wide_vs_wavg(ilam),'on');
        fplot(ax_wide_vs_wavg(ilam), @(x) exp(p2(2) + p2(1) .* log(x)), '-', 'Color', cc(find(stdev==sdv,1),:), 'DisplayName', '', 'LineWidth', 1.0);
        % change to appropriate xlim by removing fplot effect.
        ax_wide_vs_wavg(ilam).XLim = [min(wid_e), max(wid_e)];
        ax_wide_vs_wavg(ilam) = my_scatter(ax_wide_vs_wavg(ilam), 'scatter', lamx_title(lamx),...
            wid_e, lbl.we, 'log', ...
            wid_a0, 'Avg width at 0 closure stress [in]', 'log', ... % at zero closure stress
            marker_sizes, cc(find(stdev==sdv,1),:), disp_names);
        if time_mode =="all"
            % save in struct
            ana.(field_name).p2_slope = p2(1);
            ana.(field_name).p2_intercept= exp(p2(2));
        end
        %% add exp data
        % hold(ax_cdc(j), 'on');
        % for b = fields(cond_exp_all)'
        %     if cond_exp_all.(b{:}).lambda_x__in == lamx && cond_exp_all.(b{:}).lambda_y__in == lamy && cond_exp_all.(b{:}).stdev == sdv
        %
        %         plot(ax_cdc(j), cond_exp_all.(b{:}).pc, cond_exp_all.(b{:}).cond);
        %     end
        % end
        % hold(ax_cdc(j), 'off');
    end

    if err_flag > 0
        err_cases = [err_cases; cases_meet_conditions(i), err_flag];
    end
end

% show the list of destination with error
disp_error_casepaths(err_cases)

if time_mode == "all"
    jsonText = jsonencode(ana, 'PrettyPrint', true);
    % Write the JSON-formatted text to a file
    fid = fopen('ana.json', 'w');
    if fid == -1, error('Cannot create JSON file'); end
    fwrite(fid, jsonText, 'char');
    fclose(fid);
else % 600s only to get trend of cdc
    % write conductivity decline curve parameters
    jsonText = jsonencode(cdc, 'PrettyPrint', true);
    % Write the JSON-formatted text to a file
    fid = fopen('cdc.json', 'w');
    if fid == -1, error('Cannot create JSON file'); end
    fwrite(fid, jsonText, 'char');
    fclose(fid);
end

%% formatting 2 by 2 layout plots
for i = 1:numel(ax_lamx_we)
    % FIGURE1
    ax_lamx_we(i).XLim = [1, 6];
    ax_lamx_we(i).YLim = [0.125, 0.135];
    ax_lamx_we(i) = my_setting_semilogy(ax_lamx_we(i));
    % FIGURE2
    ax_lamx_wa(i).XLim = [1, 6];
    ax_lamx_wa(i).YLim = [0.004, 0.04];
    ax_lamx_wa(i) = my_setting_semilogy(ax_lamx_wa(i));
end
%% plot formatting
close(ancestor(ax_temp, 'figure'))  % close temporary plot for hist
cond0_lims = [10, 50000];
cond_lims = [10, 50000];
pc_lims = [0, 4000];
x_ratio = 0.05;
y_ratio = 0.5;

%% FIGURE1: all simu datasets
for istv = 1:numel(stdev)
    for ilam = 1:numel(lambdax)
        ax_cdc(ilam, istv).XLim = pc_lims;
        ax_cdc(ilam, istv).YLim = lims.cond;
        xlabel(ax_cdc(ilam, istv), '');
        ylabel(ax_cdc(ilam, istv), '');
        ax_cdc = my_setting_semilogy(ax_cdc);
        ax_cdc(ilam, istv) = add_ndata_on_plot(ax_cdc(ilam, istv), n(ilam, istv), x_ratio, y_ratio);
    end
end

%% FIGURE2: band plot
for istv = 1:numel(stdev)
    for ilam = 1:numel(lambdax)
        ax_avg_cdc(ilam, istv).XLim = pc_lims;
        ax_avg_cdc(ilam, istv).YLim = cond_lims;
        ax_avg_cdc(ilam, istv) = my_setting_semilogy(ax_avg_cdc(ilam, istv));
        ax_avg_cdc(ilam, istv) = add_ndata_on_plot(ax_avg_cdc(ilam, istv), n(ilam, istv), x_ratio, y_ratio);
    end
end

%% FIGURE3: Histogram plot
for istv = 1:numel(stdev)
    for ilam = 1:numel(lambdax)
        ax_hist(ilam, istv).XLim = [0, 3000];
        xlabel(ax_hist(ilam, istv), '');
        ylabel(ax_hist(ilam, istv), '');
        colororder(ax_hist(ilam, istv), cc);
    end
end

%% FIGURE8: wid_a vs conductivity
for istv = 1:numel(stdev)
    % use same xaxis for the same stdev
    xlim_for_wavg_vs_cond = get_same_xlim_for_column(ax_wavg_vs_cond(istv, :));
    for ilam = 1:numel(lambdax)
        % adding cubic law
        hold(ax_wavg_vs_cond(ilam, istv),'on');
        plot(ax_wavg_vs_cond(ilam, istv), xlim_for_wavg_vs_cond, cubic_law_mdft(xlim_for_wavg_vs_cond), '--', 'LineWidth', 1.5, 'Color', cc(1,:));
        set(ax_wavg_vs_cond(ilam, istv), 'XScale', 'log');
        ax_wavg_vs_cond(ilam, istv) = my_setting_semilogy(ax_wavg_vs_cond(ilam, istv));
        ax_wavg_vs_cond(ilam, istv).YLim = cond_lims;
        ax_wavg_vs_cond(ilam, istv).XLim = xlim_for_wavg_vs_cond;
        ax_wavg_vs_cond(ilam, istv) = add_ndata_on_plot(ax_wavg_vs_cond(ilam, istv), n(ilam, istv), x_ratio, y_ratio);
        hold(ax_wavg_vs_cond(ilam, istv),'off');
    end
end

%% FIGURE9 ax_we_vs_cond
for istv = 1:numel(stdev)
    % use same xaxis for the same stdev
    xlim_for_we_vs_cond = get_same_xlim_for_column(ax_we_vs_cond(istv, :));

    for ilam = 1:numel(lambdax)

        hold(ax_we_vs_cond(ilam, istv),'on');
        ax_we_vs_cond(ilam, istv) = my_setting_semilogy(ax_we_vs_cond(ilam, istv));
        set(ax_we_vs_cond(ilam, istv), 'XScale', 'log');
        %ax_we_vs_cond(ilam, istv).YLim = cond_lims;
        %ax_we_vs_cond(ilam, istv).XLim = xlim_for_we_vs_cond;
        ax_we_vs_cond(ilam, istv) = add_ndata_on_plot(ax_we_vs_cond(ilam, istv), n(ilam, istv), x_ratio, y_ratio);
    end
end


% legend for n1 x n3 plots
% Assign color bar to the last one tile
hold(ax_wavg_vs_cond(ilam, istv),'on');
ax_wavg_vs_cond = single_legend_for_m_by_n_plot(ax_wavg_vs_cond);
hold(ax_wavg_vs_cond(ilam, istv),'off');
ax_we_vs_cond = single_legend_for_m_by_n_plot(ax_we_vs_cond);
hold(ax_we_vs_cond(ilam, istv),'off');
ax_wavg_vs_kfw0 = single_legend_for_m_by_n_plot(ax_wavg_vs_kfw0);
% x and y labels
ax_cdc = overall_xylabels(ax_cdc, lbl.pc, lbl.kfw);
ax_avg_cdc = overall_xylabels(ax_avg_cdc, lbl.pc, lbl.kfw);
ax_hist = overall_xylabels(ax_hist, lbl.kfw, 'count');
ax_wavg_vs_cond = overall_xylabels(ax_wavg_vs_cond, lbl.wa, lbl.kfw);
ax_we_vs_cond = overall_xylabels(ax_we_vs_cond, lbl.we, lbl.kfw);

%% formatting for 1 by n plot

% for ipc = 1:5
%     for ilam = 1:numel(lambdax)
%         figs{ipc}(ilam) = my_setting_semilogy(figs{ipc}(ilam));
%         figs{ipc}(ilam) = my_plot_format(figs{ipc}(ilam));
%         figs{ipc}(ilam).XLim = [0, 5];
%         figs{ipc}(ilam).Title.String = lamx_title(lambdax(ilam));
%         figs{ipc}(ilam).YLim = [10, 10000];
%         figs{ipc}(ilam).XTick = 1:4;
%         figs{ipc}(ilam).XTickLabel = num2cell(stdev)';
% 
%     end
%     overall_xylabels(figs{ipc}, lbl.sdv, lbl.kfw)
% end

% FIGURE4: C1 vs we plot
for i = 1:numel(ax_C2_we)
    %ax_C1_we(i).XLim = cond0_lims;
    ax_C2_we(i).XLim = [0.120, 0.135];
    xlabel(ax_C2_we(i), lbl.we);
    ylabel(ax_C2_we(i), 'C2');
    set(ax_C2_we(i), 'XScale', 'log', 'YScale', 'log');
end

% FIGURE6
for i = 1:numel(ax_wavg_vs_kfw0)
    ax_wavg_vs_kfw0(i).XLim = [0.004, 0.02];
    ax_wavg_vs_kfw0(i).YLim = lims.cond0;
    ax_wavg_vs_kfw0(i).XTick = [0.004:0.004:0.2];
    xlabel(ax_wavg_vs_kfw0(i), lbl.wa);
    ylabel(ax_wavg_vs_kfw0(i), lbl.kfw0_short);
    % adding cubic law
    hold(ax_wavg_vs_kfw0(i),'on');
    plot(ax_wavg_vs_kfw0(i), ax_wavg_vs_kfw0(i).XLim, cubic_law_mdft(ax_wavg_vs_kfw0(i).XLim), '--', 'LineWidth', 1.5, 'Color', cc(6,:));
    set(ax_wavg_vs_kfw0(i), 'XScale', 'log', 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end

% FIGURE7
xlim_for_wide_vs_wavg = get_same_xlim_for_column(ax_wide_vs_wavg(:));
ylim_for_wide_vs_wavg = get_same_ylim_for_column(ax_wide_vs_wavg(:));
for i = 1:numel(ax_wide_vs_wavg)
    % plot MD corr.
    ax_wide_vs_wavg(i).XLim = xlim_for_wide_vs_wavg;
    ax_wide_vs_wavg(i).YLim = ylim_for_wide_vs_wavg;
    hold(ax_wide_vs_wavg(i), 'on')
    ax_wide_vs_wavg(i) = shade_area(ax_wide_vs_wavg(i), xlim_for_wide_vs_wavg, wavg_MD(xlim_for_wide_vs_wavg, 0), wavg_MD(xlim_for_wide_vs_wavg, 0.7), cc(5, :));
    set(ax_wide_vs_wavg(i), 'XScale', 'log', 'YScale', 'log');
    set(ax_wide_vs_wavg(i), 'XMinorGrid', 'off', 'YMinorGrid', 'off', 'LineWidth', 1.25);

    xlabel(ax_wide_vs_wavg(i), lbl.we, 'Interpreter', 'latex');
    ylabel(ax_wide_vs_wavg(i), lbl.wa, 'Interpreter', 'latex');
end


all_figures_visiblity_on()


%% External functions
function xlim = get_same_xlim_for_column(axes_1d)
a = [];
for i = 1:numel(axes_1d)
    a = [a; axes_1d(i).XLim];
end
xlim = [min(a(:,1)), max(a(:,2))];
end

function ylim = get_same_ylim_for_column(axes_1d)
a = [];
for i = 1:numel(axes_1d)
    a = [a; axes_1d(i).YLim];
end
ylim = [min(a(:,1)), max(a(:,2))];
end

function ax = add_ndata_on_plot(ax, n, x_ratio, y_ratio)
% x coordinate of the text
% y coordinate of the text
hold(ax, 'on');
x = ax.XLim(1) + (ax.XLim(2) - ax.XLim(1)) * x_ratio; % 0 is left, 1 is right
y = ax.YLim(1) + (ax.YLim(2) - ax.YLim(1)) * y_ratio; % 0 is btm, 1 is top

text(ax, x, y, ['n = ', num2str(n)]); %, ...
% 'FitBoxToText', 'on', ...
% 'BackgroundColor', 'white', ...
% 'EdgeColor', 'black');
end

function axes = overall_xylabels(axes, xname, yname)
for i = 1:numel(axes)
    xlabel(axes(i), ''); % removing xylabels for indivisual plots
    ylabel(axes(i), '');
end
t = ancestor(axes(1), 'tiledlayout');
xlabel(t, xname, 'Interpreter', 'latex');
ylabel(t, yname, 'Interpreter', 'latex');
end

function ax = shade_area(ax, xlim, curve1, curve2, color)
x2 = [xlim, fliplr(xlim)];
inBetween = [curve1, fliplr(curve2)];
fill(ax, x2, inBetween, color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% changing the order so that fill doesn't cover other plots.
h = get(ax,'Children');
% Set the children in reverse order
set(ax,'Children', [h(2:end); h(1)])
end

function ax = single_legend_for_m_by_n_plot(ax)
target_ax = ax(end, end);
hold(target_ax, 'on');
lgh = legend(target_ax);
% Position the colorbar as a global colorbar representing all tiles
lgh.Layout.Tile = 'east';
legend_strings = string(get(lgh, 'String'));
% Remove lines from the legend
scatter_only = findobj(target_ax, 'Type', 'scatter');
legend_idx = ~strcmp(legend_strings, '') & ~startsWith(legend_strings, 'data');
if ~isempty(scatter_only)
    legend(scatter_only, 'Location', 'southoutside');
    set(lgh, 'FontName', 'Segoe UI', 'FontSize', 10, 'LineWidth', 1);
    box(lgh,'on');
end
end


% Update legend
function disp_error_casepaths(err_cases)
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
end

function all_figures_visiblity_on()
allFigures = findall(0, 'Type', 'figure');
% Loop through all figures and set them to visible
for fig = allFigures'
    fig.Visible = 'on';
end
end