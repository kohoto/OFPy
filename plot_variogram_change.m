% This is to plot before and after vairograms.

%% Input the stdev and lambdas here.
lamx = 6.0;
lamy = 1.0;
sdv = 0.075;

%% Main part of the code
file_name = 'variogram.json';
% search variogram files only from the 600s etching results.
casepaths_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, '600');
batches = [100:1:2000];
dataStruct = struct();
for casepath_meet_conditions = casepaths_meet_conditions
    dataStruct = store_batch_json(dataStruct, file_name, casepath_meet_conditions);
end

ax = create_tiledlayout(1, 1, 0.5);
for seed_fieldname = fieldnames(dataStruct)'
    ax = plot_variogram(ax, dataStruct.(seed_fieldname{:}));
end

% formatting plot
ax.XLim = [0, 7];
xlabel(ax, 'Lab distance [in]');
ylabel(ax, '\gamma');
