%function check_conductivity()
clear; close all;
set(groot, 'defaultAxesTitleInterpreter','latex');
cc = tamu_color();
lims = my_lims();
lbl = my_labels();

cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
wavg_MD = @(we_inch, stdd_for_k) 0.56 .* erf(0.8 * stdd_for_k) .* we_inch .^ (0.83);
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
time_mode = 'all'; % or 'all' % do you wanna include conductivities from other etching time cases?
lambdax = [0.1, 0.3, 0.5 0.7];
lambday = [0.1]; % must be only one number to fit all plots in figuress.
stdev = [0.1, 0.3, 0.5, 0.7];

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
ax_cdc = create_tiledlayout(n3, n1, 1);
ax_r = create_tiledlayout(n3, n1, 1);

%% main program
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng';
batch_dirs = dir(fullfile(intermCases_dir));

err_cases = ["folder_name", 0];
for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    ilam = find(lambdax == lamx);
    isdv = find(stdev == sdv);
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
        ax_cdc(ilam, isdv) = my_scatter(ax_cdc(ilam, isdv), 'alphaline', [search_condition, '\nn = ', num2str(numel(fields(dataStruct)))],...
            repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
            cond_simu, 'Conductivity [md-ft]', 'normal', ...
            marker_sizes, cc(4,:), disp_names);
        hold(ax_cdc(ilam, isdv), 'on')


        pcs = [0:1000:4000];
        npc = numel(pcs);
        [kfw_NK, kfw_MD] = deal(nan(1, npc));

        for ipc = 1:5
            % getConductivity(wIdeal_inch, f_c, CL, E_mpsi, pc_psi, sigma, lambdax, lambdaz, test1)
            casename = fieldnames(dataStruct);
            [kfw_NK(1, ipc), kfw_MD(1, ipc)] = getConductivity(dataStruct.(casename{:}).wid_e__in, 1, 0.005, 4, pcs(ipc), sdv, lamx, lamy);
        end
        %plot(ax_cdc(ilam, istv), pcs, kfw_NK); hold on;
        plot(ax_cdc(ilam, isdv), pcs, kfw_MD, 'k', 'LineWidth', 2);


        scatter(ax_r(ilam, isdv), cond_simu(1,2:5), kfw_MD(1, 2:5));
        hold(ax_r(ilam, isdv), "on")
    end



end

for isdv = 1:numel(stdev)
    for ilam = 1:numel(lambdax)
        ax_cdc(ilam, isdv).XLim = lims.pc;
        %ax_cdc(ilam, istv).YLim = lims.cond;
        xlabel(ax_cdc(ilam, isdv), '');
        ylabel(ax_cdc(ilam, isdv), '');
        ax_cdc = my_setting_semilogy(ax_cdc);
        plot(ax_r(ilam, isdv), cond_simu(1,2:5), cond_simu(1,2:5));
        hold(ax_r(ilam, isdv), "on")
    end
end
overall_xylabels(ax_cdc, lbl.pc,lbl.kfw)
overall_xylabels(ax_r, 'Simulated', 'Correlation')

%% external function
function overall_xylabels(axes, xname, yname)
t = ancestor(axes(1), 'tiledlayout');
xlabel(t, xname, 'Interpreter', 'latex');
ylabel(t, yname, 'Interpreter', 'latex');
end