clear; close all;
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
stdev = 0.1;
lambdas = 'lambda1_0-1_0';

%% Main part of the code
% Specify the file path
dissolCasesDir = 'C:/Users/tohoko.tj/dissolCases/';
seedDir = [dissolCasesDir, 'stdev', strrep(num2str(stdev), '.', '_'), '-', lambdas, '/'];
file_name = 'variogram.json';

batches = [100:1:2000];
dataStruct = struct();
for i = 1 : length(batches)
    batchName = ['seed', sprintf('%04d', batches(i)), '-stdev', strrep(num2str(stdev), '.', '_')];
    % Get a list of all files and folders in this directory
    dataStruct = store_batch_json(dataStruct, file_name, cases_meet_condition);
end

[cond_simu, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, 'cond__mdft');

fig = my_scatter('plot', 'Conductivity',...
    repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
    cond_simu, 'Conductivity [md-ft]', 'log', ...
    marker_sizes, colors, disp_names);

fig2 = my_scatter('box', 'Conductivity',...
    repmat(pc, numel(disp_names), 1), 'Closure stress [psi]', 'normal', ...
    cond_simu, 'Conductivity [md-ft]', 'log', ...
    marker_sizes, colors, disp_names);

figure;
tiledlayout(2,2); nexttile;
histogram(cond_simu(:, 2), 'BinWidth', 10); xlim([0, 500]); nexttile;
histogram(cond_simu(:, 3), 'BinWidth', 10); xlim([0, 500]); nexttile;
histogram(cond_simu(:, 4), 'BinWidth', 10); xlim([0, 500]); nexttile;
histogram(cond_simu(:, 5), 'BinWidth', 10); xlim([0, 500]);

% plot etched width
[wid_e, wid_a, marker_sizes, colors, disp_names] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in');

fig4 = my_scatter('plot', 'Etched width variation',...
    wid_e, 'Etched width [in]', 'log', ...
    wid_a, 'Avg width [in]', 'log', ...
    marker_sizes, colors, disp_names);