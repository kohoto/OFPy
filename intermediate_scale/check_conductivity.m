%function check_conductivity()
clear; close all;
cc = tamu_color();
lims = my_lims();
lbl = my_labels();

cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
wavg_MD = @(we_inch, stdd_for_k) 0.56 .* erf(0.8 * stdd_for_k) .* we_inch .^ (0.83);
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
time_mode = 'all'; % or 'all' % do you wanna include conductivities from other etching time cases?
lambdaxd = [0.1, 0.3, 0.5 0.7];
lambdayd = [0.1]; % must be only one number to fit all plots in figuress.
stdevd = [0.1, 0.3, 0.5, 0.7];
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


%% prep figures
ax_r_all = create_tiledlayout(1, 1, 0.6);
ax_r = create_tiledlayout(n3, n1, 1);
ax_cdc = create_tiledlayout(n3, n1, 1);

% figure formatting before plotting
ax_r_all = my_settings_for_R2_plot(ax_r_all);

for isdv = 1:numel(stdevd)
    for ilam = 1:numel(lambdaxd)
        ax_cdc(ilam, isdv).XLim = lims.cond;
        ax_cdc = my_setting_semilogy(ax_cdc);
        % R2 check plot
        ax_r(ilam, isdv) = my_settings_for_R2_plot(ax_r(ilam, isdv));
    end
end
%% main program
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng';
batch_dirs = dir(fullfile(intermCases_dir));

err_cases = ["folder_name", 0];
for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    ilam = find(lambdaxd == lamx);
    isdv = find(stdevd == sdv);
    case_dir = ['k', num2str(ilam), num2str(ilam)];

    % cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, time_mode);
    cases_meet_conditions = [];
    % Loop over the searching_dir
    for batch_dir = batch_dirs'
        case_dir_name = fullfile(batch_dir.folder, batch_dir.name, ['k', num2str(ilam), num2str(isdv)]);
        if isfolder(case_dir_name)
            cases_meet_conditions = [cases_meet_conditions, string(case_dir_name)];
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
            
        [kfw_NK, kfw_MD] = deal(nan(ncase, npc));

        for ipc = 1:5
            % getConductivity(wIdeal_inch, f_c, CL, E_mpsi, pc_psi, sigma, lambdax, lambdaz, test1)
            icase = 0; % reset icase count
            for casename = fieldnames(dataStruct)'
                icase = icase + 1;
                [kfw_NK(icase, ipc), kfw_MD(icase, ipc)] = getConductivity(dataStruct.(casename{:}).wid_e__in, 1, 0.005, 4, pcs(ipc), sdv, lamx, lamy);
                %[kfw_NK(icase, ipc), kfw_MD(icase, ipc)] = getConductivity(dataStruct.(casename{:}).w0_Mou, 1, 0.005, 4, pcs(ipc), sdv, lamx, lamy);
            end
        end
        
        %% FIGURE1: CDC visual comparison
        %plot(ax_cdc(ilam, istv), pcs, kfw_NK); hold on;
        hold(ax_cdc(ilam, isdv), 'on');
        plot(ax_cdc(ilam, isdv), pcs, kfw_MD, 'k', 'LineWidth', 2);

        %% FIGURE2: R2 comparison
        hold(ax_r(ilam, isdv), 'on');
        ax_r(ilam, isdv) = my_scatter(ax_r(ilam, isdv), 'scatter', '',...
            cond_simu(:,2:5), 'Simulation', 'log', ...
            kfw_MD(:, 2:5), 'Correlation', 'log', ...
            12, cc([1:ncase],:), num2str([1:ncase]'));

        hold(ax_r_all, 'on');
        ax_r_all = my_scatter(ax_r_all, 'scatter', '',...
            cond_simu(:,2:5), 'Simulation', 'log', ...
            kfw_MD(:, 2:5), 'Correlation', 'log', ...
            12, cc([1:ncase],:), num2str([1:ncase]'));

        R = corrcoef(cond_simu(:,2:5), kfw_MD(:,2:5));
        R2 = R(1,2)^2;
        disp(['R = ', num2str(R2)])
        ax_r(ilam, isdv) = add_ndata_on_plot(ax_r(ilam, isdv), R2, x_ratio, y_ratio);

    end
end



ax_cdc = overall_xylabels(ax_cdc, lbl.pc,lbl.kfw);
ax_r = overall_xylabels(ax_r, 'Simulated', 'Correlation');

all_figures_visiblity_on();

function ax = my_settings_for_R2_plot(ax)
% R2 check plot
hold(ax, 'on');
plot(ax, [0.1, 500000], [0.1 500000]);
hold(ax, "on");
set(ax, 'XScale', 'log', 'YScale', 'log');
set(ax, 'XMinorGrid', 'off', 'YMinorGrid', 'off', 'LineWidth', 1.25);
ax.XLim = [0.1, 500000];
ax.YLim = [0.1, 500000];
end
