% This is to plot before and after vairograms of experimental data.

%% Input the stdev and lambdas here.
lamx = 1.0;
lamy = 1.0;
sdv = 0.1;

%% Main part of the code
% prep experimental data
vari_exp_all = struct();
[vari_exp_all, err_cases] = add_exp_data(vari_exp_all, 'variogram.json');

%% find exp data that meets conditions
ax = create_tiledlayout(1, 1, 0.5);
for icase = fieldnames(vari_exp_all)'
    % if isfield(cond_exp_all, icase{:})
    %     if (cond_exp_all.(icase{:}).lambda_x__in == lamx && ...
    %             cond_exp_all.(icase{:}).lambda_y__in == lamy && ...
    %             cond_exp_all.(icase{:}).stdev == sdv)

            ax = plot_variogram(ax, vari_exp_all.(icase{:}));
    %     end
    % end
end

% formatting plot
ax.XLim = [0, 7];
ax.YLim = [0, 3];
xlabel(ax, 'Lab distance [in]');
ylabel(ax, '\gamma');