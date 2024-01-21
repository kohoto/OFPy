clear; close all;
cc = tamu_color();
% Specify the file path
dissolCasesDir = 'C:/Users/tohoko.tj/dissolCases/';
batchName = 'seed6000-stdev0_05';

% Get a list of all files and folders in this directory
dataStruct = store_batch_json(struct(), 'cond.json', dissolCasesDir, batchName);

[cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft');
[cond_cubic, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond_cubic_avg__mdft');

fig = my_scatter('plot', 'Conductivity',...
    repmat(pc, 2 * numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
    [cond_cubic; cond_simu], 'Conductivity [md-ft]', 'log', ...
    repmat(marker_sizes, 2, 1), ...
    repmat(colors, 2, 1), ...
    repmat(disp_names, 2, 1));



