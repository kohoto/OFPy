function plot_variogram_all()
clear; close all;
cc = tamu_color();

%% Input the stdev and lambdas here.
lambdax = [1.0, 2.0, 4.0, 6.0];
lambday = [1.0];
stdev = [0.025, 0.05, 0.075, 0.1];

n1 = numel(lambdax);
n2 = numel(lambday); % must be 1
n3 = numel(stdev);
n_search_conditions = n1 * n2 * n3;
search_conditions = [reshape(repmat(lambdax, n2*n3, 1),1,[]); ...
    reshape(repmat(lambday, n3, n1),1,[]); ...
    reshape(repmat(stdev, n1*n2, 1).',1,[])];

fig = figure('Color',[1 1 1]);
t = tiledlayout(fig, n1, n3);
ax = [];
for j = 1:size(search_conditions, 2)
    ax = [ax; nexttile(t)];
end

% prep experimental data
vari_exp_all = struct();
cond_exp_all = struct();
[vari_exp_all, err_cases] = add_exp_data(vari_exp_all, 'variogram.json');
[cond_exp_all, err_cases] = add_exp_data(cond_exp_all, 'cond.json');


for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, 'all');

    dataStruct = struct();
    for i = 1 : length(cases_meet_conditions)
        [dataStruct, err_flag] = store_batch_json(dataStruct, 'variogram.json', cases_meet_conditions(i));
        if err_flag >= 1
            err_cases = [err_cases; cases_meet_conditions(i), err_flag];
        end
    end


    search_condition = strrep(['lambda', sprintf('%.1f', lamx), '-' , sprintf('%.1f', lamy), '-stdev', num2str(sdv)], '.', '_');
    if isempty(fieldnames(dataStruct))
        disp(['no data with the condition: ', search_condition]);
    else % if there's something in dataStruct, add plot on axes

        % plot variogram of before and after, top and btm.
        casenames = fieldnames(dataStruct);
        for i = 1:numel(casenames)
            casename = casenames(i);
            ax(j) = plot_variogram(ax(j), dataStruct.(casename{:}));
        end
    end
    
    %% find exp data that meets conditions
    for icase = fieldnames(vari_exp_all)'
        if isfield(cond_exp_all, icase{:})
            if (cond_exp_all.(icase{:}).lambda_x__in == lamx && ...
                    cond_exp_all.(icase{:}).lambda_y__in == lamy && ...
                    cond_exp_all.(icase{:}).stdev == sdv)

                ax(j) = plot_variogram(ax(j), vari_exp_all.(icase{:}));
            end
        end
    end


end
disp(err_cases);

end

