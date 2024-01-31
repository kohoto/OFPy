function plot_for_specific_time()
clear; close all;
cc = tamu_color();
cubic_law_mdft = @(w_inch) (w_inch .* 0.0254) .^ 3 ./ 12 .* 1.0133e15 .* 3.28084;
%% first read all no matter what. Then filter dataStruct. Then plot.
%% Input the stdev and lambdas here.
lambdax = [1.0, 2.0, 4.0, 6.0];
lambday = [1.0]; % must be only one number to fit all plots in figuress.
stdev = [0.025, 0.05, 0.075, 0.1];
file_name = 'cond.json';
colored_by = 'lambda_x__in';
sized_by = 'wid_e__in';

n1 = numel(lambdax);
n2 = numel(lambday);
n3 = numel(stdev);
search_conditions = [reshape(repmat(lambdax, n2*n3, 1),1,[]); ...
    reshape(repmat(lambday, n3, n1),1,[]); ...
    reshape(repmat(stdev, n1*n2, 1).',1,[])];

[mean_wid_e, mean_wid_a] = deal(nan(numel(stdev), numel(lambdax)));

%% prep figures
ax_lambda_vs_wid_e = create_tiledlayout(1, 1);
ax_lambda_vs_wavg = create_tiledlayout(1, 1);
ax_lambda_vs_wid_e_avg = create_tiledlayout(1, 1);
ax_lambda_vs_wavg_avg = create_tiledlayout(1, 1);

%% main program
err_cases = ["folder_name", 0];
for j = 1 : size(search_conditions, 2)
    lamx = search_conditions(1, j);
    lamy = search_conditions(2, j);
    sdv = search_conditions(3, j);
    cases_meet_conditions = find_cases_from_conditions(lamx, lamy, sdv, '600');

    % if color by search conditions, assign the color code here
    if isnumeric(colored_by) || colored_by == "search_conditions"
        colored_by = cc(mod(j, size(cc, 1)) + 1, :) + floor(j / size(cc, 1)) * 10 /255; % make them darker and darker once used first 9 colors
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

        % FIGURE1: lmabda ratio vs average etched width plot
        [wid_e, wid_a, marker_sizes, colors, disp_names] = store_var_from_struct(dataStruct, 'wid_e__in', 'avg_w__in', colored_by, sized_by);
        
        field_name = strrep(['lam', num2str(lamx), '_', num2str(lamy), '_', num2str(sdv)], '.', '_');
        ax_lambda_vs_wid_e = my_scatter(ax_lambda_vs_wid_e, 'scatter', '',...
        repmat((lamx / lamy), 1, numel(wid_e)), 'Lambda ratio', 'normal', ...
        wid_e', 'Etched width [in]', 'normal', ...
        50, cc(find(sdv==stdev, 1),:), sprintf("stdev = %f",sdv));

        % showing only for average width at 0 closure stress
        ax_lambda_vs_wavg = my_scatter(ax_lambda_vs_wavg, 'scatter', '',...
            repmat((lamx / lamy), 1, numel(wid_e)), 'Lambda ratio', 'normal', ...
            wid_a', 'Average width at 0 closure stress [in]', 'normal', ...
            50, cc(find(sdv==stdev, 1),:), sprintf("stdev = %f",sdv));


        % cond_at_pc_wo_naninf = cond_at_pc(~isnan(cond_at_pc) & ~isinf(cond_at_pc));
        mean_wid_a(find(sdv==stdev, 1), find(lamx==lambdax, 1)) = mean(wid_a, 1);
        mean_wid_e(find(sdv==stdev, 1), find(lamx==lambdax, 1)) = mean(wid_e, 1);
        sdv_wid_a(find(sdv==stdev, 1), find(lamx==lambdax, 1)) = std(wid_a);
        sdv_wid_e(find(sdv==stdev, 1), find(lamx==lambdax, 1)) = std(wid_e);
    end
end

% showing only for average width at 0 closure stress
for i = 1:numel(stdev)
    fill(ax_lambda_vs_wid_e_avg, [lambdax, fliplr(lambdax)], [mean_wid_e(i, :) + sdv_wid_e(i, :), fliplr(mean_wid_e(i, :) - sdv_wid_e(i, :))], cc(i, :), 'FaceAlpha', 0.6);
    hold(ax_lambda_vs_wid_e_avg, 'on');
end
ax_lambda_vs_wid_e_avg = my_scatter(ax_lambda_vs_wid_e_avg, 'plot', '',...
    repmat((lambdax), size(mean_wid_e, 1), 1), 'Lambda ratio', 'normal', ...
    mean_wid_e, 'Average width at 0 closure stress [in]', 'normal', ...
    repmat(10, [numel(stdev), 1]), cc([1:4],:), num2str(stdev'));

for i = 1:numel(stdev)
    fill(ax_lambda_vs_wavg_avg, [lambdax, fliplr(lambdax)], [mean_wid_a(i, :) + sdv_wid_a(i, :), fliplr(mean_wid_a(i, :) - sdv_wid_a(i, :))], cc(i, :), 'FaceAlpha', 0.6);
    hold(ax_lambda_vs_wavg_avg, 'on');
end
ax_lambda_vs_wavg_avg = my_scatter(ax_lambda_vs_wavg_avg, 'plot', '',...
    repmat((lambdax), size(mean_wid_a, 1), 1), 'Lambda ratio', 'normal', ...
    mean_wid_a, 'Average width at 0 closure stress [in]', 'normal', ...
    repmat(10, [numel(stdev), 1]), cc([1:4],:), num2str(stdev'));

%% plot formatting
% FIGURE1: cdc plot
ax_lambda_vs_wid_e.XLim = [0, 6];
ax_lambda_vs_wid_e.YLim = [0.126, 0.134];

ax_lambda_vs_wavg.XLim = [0, 6];
ax_lambda_vs_wavg.YLim = [0, 0.05];

end
