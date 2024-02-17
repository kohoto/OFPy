clear; close all;
cc = tamu_color();
lims = my_lims();
pc_lims = [0, 4000];
cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
wavg_MD = @(we_inch, stdd_for_k) 0.56 .* erf(0.8 * stdd_for_k) .* we_inch .^ (0.83);
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
time_mode = '600'; % or 'all' % do you wanna include conductivities from other etching time cases?
lambdax = [6.0];
lambday = [1.0]; % must be only one number to fit all plots in figuress.
stdev = [0.075];
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
ax_cdc = create_tiledlayout(n3, n1, 1);
ax_vario = create_tiledlayout(1, 2, 0.5);
%% param display names
pc_name = 'P_{c} [psi]';
cond_name = 'k_{f}w [md-ft]';
cond0_name = '(k_{f}w)_{0} [md-ft]';
we_name = 'w_{e} [in]';
wa_name = 'w_{avg} [in]';
sdv_name = '\sigma';
lamx_name = '\lambda_{x} [in]';

%% prep experimental data
cond_exp_all = struct();
[cond_exp_all, ~] = add_exp_data(cond_exp_all, 'cond.json');
[vari_exp_all, ~] = add_exp_data(struct(), 'variogram.json');

%% main program
err_cases = ["folder_name", 0];
ana = struct();
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
    vario_data = struct();

    for i = 1 : length(cases_meet_conditions)
        [dataStruct, err_flag] = store_batch_json(dataStruct, 'cond.json', cases_meet_conditions(i));
        [vario_data, ~] = store_batch_json(vario_data, 'variogram.json', cases_meet_conditions(i));
        if err_flag > 1
            err_cases = [err_cases; cases_meet_conditions(i), err_flag];
        end
    end

    search_condition = ['lambda', sprintf('%.1f', lamx), '-' , sprintf('%.1f', lamy), '-stdev', num2str(sdv)];
    if isempty(fieldnames(dataStruct))
        disp(['no data with the condition: ', search_condition]);
    else % if there's something in dataStruct, add plot on axes
        % read data into matrix
        [wid_e, wid_a, ~, ~, ~] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in', colored_by, sized_by);
        [cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft', colored_by, sized_by);


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
        ax_lamx_we(istv) = my_scatter(ax_lamx_we(istv), 'scatter', [sdv_name, ' = ', num2str(sdv)],...
            lamx, lamx_name, 'normal', ...
            wid_e', we_name, 'normal', ...
            20, cc(find(stdev==sdv, 1),:), num2str(sdv));
        hold(ax_lamx_we(istv), 'on')

        %% FIGURE2: cdc plot
        ax_cdc(ilam, istv) = my_scatter(ax_cdc(ilam, istv), 'alphaline', [search_condition, 'n = ', num2str(numel(fields(dataStruct)))],...
            repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
            cond_simu, 'Conductivity [md-ft]', 'normal', ...
            marker_sizes, cc(4,:), disp_names);
        hold(ax_cdc(ilam, istv), 'on')
        plot(ax_cdc(ilam, istv), pc, mean_cdc, '-', 'Color', cc(1, :), 'LineWidth', 1.5);
        % plot(ax_cdc(ilam, istv), pc, mean_cdc - stdv_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        % plot(ax_cdc(ilam, istv), pc, mean_cdc + stdv_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        plot(ax_cdc(ilam, istv), pc, p90_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        plot(ax_cdc(ilam, istv), pc, p10_cdc, ':', 'Color', cc(1, :), 'LineWidth', 1.5);
        
        %% add exp data
        for b = fields(cond_exp_all)'
            if cond_exp_all.(b{:}).lambda_x__in == lamx && cond_exp_all.(b{:}).lambda_y__in == lamy && cond_exp_all.(b{:}).stdev == sdv

                % FIGURE1
                ax_lamx_we(istv) = my_scatter(ax_lamx_we(istv), 'scatter', '',...
                lamx, lamx_name, 'normal', ...
                cond_exp_all.(b{:}).wid_e__in, we_name, 'normal', ...
                20, cc(end-2, :), num2str(sdv));
                hold(ax_lamx_we(istv), 'on')
                
                % FIGURE 2
                plot(ax_cdc(j), cond_exp_all.(b{:}).pc, cond_exp_all.(b{:}).cond, '-', 'Color', cc(end-2, :), 'LineWidth', 2);
                hold(ax_cdc(j), 'on')

                % FIGURE3
                ax_vario(2) = plot_variogram(ax_vario(2), vari_exp_all.(b{:}));
            end
        end
    end
    % FIGURE3: variogram plot
    for b = fields(vario_data)'
        ax_vario(1) = plot_variogram(ax_vario(1), vario_data.(b{:}));
    end

end

% FIGURE2: CDC plot
ax_cdc(ilam, istv).XLim = lims.pc;
ax_cdc(ilam, istv).YLim = lims.cond;
ax_cdc = my_setting_semilogy(ax_cdc);
