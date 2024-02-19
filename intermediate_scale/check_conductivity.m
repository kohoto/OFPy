%function check_conductivity()
clear; close all;
cc = tamu_color();
lims = my_lims();
lbl = my_labels();

cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
wavg_MD = @(we_inch, stdd_for_k) 0.56 .* erf(0.8 * stdd_for_k) .* we_inch .^ (0.83);
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
%mode = 'intermediate';
mode = 'experiment';

time_mode = '600'; % or 'all' % do you wanna include conductivities from other etching time cases?

if mode=="intermediate"
    lambdaxd = [0.1, 0.3, 0.5 0.7];
    lambdayd = [0.1]; % must be only one number to fit all plots in figuress.
    stdevd = [0.1, 0.3, 0.5, 0.7];
    R_lims = [10, 500000];
else
    lambdaxd = [1, 2, 4, 6];
    lambdayd = [1]; % must be only one number to fit all plots in figuress.
    stdevd = [0.025, 0.05, 0.075, 0.1];
    R_lims = [10, 10000];
end

x_ratio = 0.000001;
y_ratio = 0.5;
file_name = 'cond.json';
colored_by = 'stdev';
sized_by = '';

n1 = numel(lambdaxd);
n2 = numel(lambdayd);
n3 = numel(stdevd);
search_conditions = [reshape(repmat(lambdaxd, n2*n3, 1),1,[]); ...
    reshape(repmat(lambdayd, n3, n1),1,[]); ...
    reshape(repmat(stdevd, n1*n2, 1).',1,[])];

lx = 7;
sdv0 = 0.1;
%% prep figures
ax_r_all = create_tiledlayout(1, 1, 0.6);
ax_r = create_tiledlayout(n3, n1, 1);
ax_cdc = create_tiledlayout(n3, n1, 1);

% figure formatting before plotting
ax_r_all = my_settings_for_R2_plot(ax_r_all, R_lims);

for isdv = 1:numel(stdevd)
    for ilam = 1:numel(lambdaxd)
        ax_cdc(ilam, isdv).XLim = lims.pc;
        ax_cdc = my_setting_semilogy(ax_cdc);
        % R2 check plot
        ax_r(ilam, isdv) = my_settings_for_R2_plot(ax_r(ilam, isdv), R_lims);
    end
end
%% main program
%intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng';
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng';
batch_dirs = dir(fullfile(intermCases_dir));

err_cases = ["folder_name", 0];
kfw_w_pc_all = [];
kfw_w_pc_ub_all = [];
kfw_w_pc_lb_all = [];
cond_simu_w_pc_all = [];
for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    ilam = find(lambdaxd == lamx);
    isdv = find(stdevd == sdv);

    if mode=="intermediate"
        case_dir = ['k', num2str(ilam), num2str(ilam)];

        % cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, time_mode);
        cases_meet_conditions = [];
        % Loop over the searching_dir
        for batch_dir = batch_dirs'
            case_dir_name = fullfile(batch_dir.folder, batch_dir.name, case_dir);
            if isfolder(case_dir_name)
                cases_meet_conditions = [cases_meet_conditions, string(case_dir_name)];
            end
        end
    else
        cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, time_mode);
        % if color by search conditions, assign the color code here
        if isnumeric(colored_by) || colored_by == "search_conditions"
            colored_by = cc(mod(j, size(cc, 1)) + 1, :) + floor(j / size(cc, 1)) * 10 /255; % make them darker and darker once used first 9 colors
        end

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
        % read data into matrix
        [wid_e, wid_a, ~, ~, ~] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in', colored_by, sized_by);
        [cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft', colored_by, sized_by);

        %% FIGURE2: cdc plot
        ax_cdc(ilam, isdv) = my_scatter(ax_cdc(ilam, isdv), 'alphaline', {search_condition; ['n = ', num2str(numel(fields(dataStruct)))]},...
            repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
            cond_simu, 'Conductivity [md-ft]', 'normal', ...
            marker_sizes, cc(4,:), disp_names);
        hold(ax_cdc(ilam, isdv), 'on')



        pcs = [0:1000:4000];
        npc = numel(pcs);
        ncase = numel(fieldnames(dataStruct));

        kfw = nan(ncase, npc);
        delta = nan(ncase, npc);

        for ipc = 1:5
            % getConductivity(wIdeal_inch, f_c, CL, E_mpsi, pc_psi, sigma, lambdax, lambdaz, test1)
            icase = 0; % reset icase count
            for casename = fieldnames(dataStruct)'
                icase = icase + 1;
                if mode=="intermediate"
                    f_c=1; CL=0.005; E_mpsi=4;
                    [A, B, C] = MD_correlation_params(f_c, CL, E_mpsi, sdv, lamx, lamy);
                    kfw(icase, ipc) = get_conductivity(dataStruct.(casename{:}).wid_e__in, pcs(ipc), A, B, C);
                else
                    E_psi = 2.9e6;
                    [A, B, C] = TJ_correlation_params(E_psi / 1e6, sdv /sdv0, lamx / lx);
                    kfw(icase, ipc) = get_conductivity(dataStruct.(casename{:}).wid_e__in, pcs(ipc), A, B, C);
                    delta = get_delta(sdv /sdv0, lamx / lx);
                end
            end
        end

        %% FIGURE1: CDC visual comparison
        %plot(ax_cdc(ilam, istv), pcs, kfw_NK); hold on;
        hold(ax_cdc(ilam, isdv), 'on');
        plot(ax_cdc(ilam, isdv), pcs, kfw, 'k', 'LineWidth', 2);

        %% FIGURE2: R2 comparison
        hold(ax_r(ilam, isdv), 'on');
        ax_r(ilam, isdv) = my_scatter(ax_r(ilam, isdv), 'errorbar', '',...
            cond_simu(:,2:5), 'Simulation', 'log', ...
            kfw(:, 2:5), 'Correlation', 'log', ...
            2 .* delta', cc(2,:), num2str([1:ncase]'));

        hold(ax_r_all, 'on');
        ax_r_all = my_scatter(ax_r_all, 'scatter', '',...
            cond_simu(:,2:5), 'Simulation', 'log', ...
            kfw(:, 2:5), 'Correlation', 'log', ...
            12, cc(2,:), num2str([1:ncase]'));
        
        kfw_w_pc_ub = kfw(:, 2:5) + 2 * delta(1);
        kfw_w_pc_lb = kfw(:, 2:5) - 2 * delta(2);
        kfw_w_pc = kfw(:, 2:5);
        cond_simu_w_pc = cond_simu(:, 2:5);
        if (lamx ~= 1 && sdv ~= 0.05)
            kfw_w_pc_all = [kfw_w_pc_all; kfw_w_pc(:)];
            kfw_w_pc_ub_all = [kfw_w_pc_ub_all; kfw_w_pc_ub(:)];
            kfw_w_pc_lb_all = [kfw_w_pc_lb_all; kfw_w_pc_lb(:)];
            cond_simu_w_pc_all = [cond_simu_w_pc_all; cond_simu_w_pc(:)];
        end
        top = min([max([zeros(size(kfw_w_pc_ub(:))), log(cond_simu_w_pc(:)) - log(kfw_w_pc_ub(:))], [], 2), ...
                  max([zeros(size(kfw_w_pc_lb(:))), log(kfw_w_pc_lb(:)) - log(cond_simu_w_pc(:))], [], 2)], [], 2);

        R2 = 1 - sum(top .^2) ./ sum((log(kfw_w_pc(:)) - mean(log(kfw_w_pc(:)))) .^2);
        % R = corrcoef(cond_simu(:,2:5), kfw(:,2:5));
        % R2 = R(1,2)^2;
        disp(['R = ', num2str(R2)])
        if mode == "experiment"
            ax_r(ilam, isdv) = add_ndata_on_plot(ax_r(ilam, isdv), R2, x_ratio, y_ratio);
        end

    end
end

if mode == "experiment"
    top = min([max([zeros(size(kfw_w_pc_ub_all(:))), log(cond_simu_w_pc_all(:)) - log(kfw_w_pc_ub_all(:))], [], 2), ...
               max([zeros(size(kfw_w_pc_lb_all(:))), log(kfw_w_pc_lb_all(:)) - log(cond_simu_w_pc_all(:))], [], 2)], [], 2);
    
    R2 = 1 - sum((top) .^2) ./ sum((log(kfw_w_pc_all(:)) - mean(log(kfw_w_pc_all(:)))) .^2);
    % R = corrcoef(cond_simu(:,2:5), kfw(:,2:5));
    % R2 = R(1,2)^2;
    disp(['R_all = ', num2str(R2)])
end

ax_cdc = overall_xylabels(ax_cdc, lbl.pc,lbl.kfw);
ax_r = overall_xylabels(ax_r, 'Simulated', 'Correlation');

all_figures_visiblity_on();

function ax = my_settings_for_R2_plot(ax, R_lims)
% R2 check plot
hold(ax, 'on');
plot(ax, R_lims, R_lims);
%TODO how to express up and down range
% delta = get_delta(1, 1);
% plot(ax, [10, 10000], [10, 10000]+delta(1));

hold(ax, "on");
set(ax, 'XScale', 'log', 'YScale', 'log');
set(ax, 'XMinorGrid', 'off', 'YMinorGrid', 'off', 'LineWidth', 1.25);
ax.XLim = R_lims;
ax.YLim = R_lims;
end
