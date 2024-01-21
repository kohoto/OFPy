clear; close all;
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
lambdax = 2.0;
lambday = 1.0;
stdev = 0.1;
file_name = 'cond.json';
colored_by = 'lambda_x__in';
sized_by = 'wid_e__in';

figs1 = figure('Color',[1 1 1]);
figs2 = figure('Color',[1 1 1]);
figs3 = figure('Color',[1 1 1]);
figs4 = figure('Color',[1 1 1]);

cases_meet_conditions = find_cases_from_conditions(lambdax, lambday, stdev);

dataStruct = struct();
for i = 1 : length(cases_meet_conditions)
    dataStruct = store_batch_json(dataStruct, 'cond.json', cases_meet_conditions(i));
end

[cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft', colored_by, sized_by);

% figure name
search_condition = strrep(['lambda', sprintf('%.1f', lambdax), '-' , sprintf('%.1f', lambday), '-stdev', num2str(stdev)], '.', '_');

% Create figure
figs1 = my_scatter(figs1, 'plot', ['Conductivity all:', search_condition],...
    repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
    cond_simu, 'Conductivity [md-ft]', 'log', ...
    marker_sizes, colors, disp_names);

figs2 = my_scatter(figs2, 'box', ['Conductivity box plot:', search_condition],...
    repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
    cond_simu, 'Conductivity [md-ft]', 'log', ...
    marker_sizes, colors, disp_names);

figs3 = tiledlayout(2,2);
title(search_condition)
nexttile; histogram(cond_simu(:, 2), 'BinWidth', 10); xlim([0, 500]);
nexttile; histogram(cond_simu(:, 3), 'BinWidth', 10); xlim([0, 500]);
nexttile; histogram(cond_simu(:, 4), 'BinWidth', 10); xlim([0, 500]);
nexttile; histogram(cond_simu(:, 5), 'BinWidth', 10); xlim([0, 500]);


% plot etched width
[wid_e, wid_a, marker_sizes, colors, disp_names] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in', colored_by, sized_by);

figs4 = my_scatter(figs4, 'plot', ['Etched width variation:', search_condition],...
    wid_e, 'Etched width [in]', 'log', ...
    wid_a, 'Avg width [in]', 'log', ...
    marker_sizes, colors, disp_names);