%function analyze_slopes()
clear; close all;
cc = tamu_color();

varxname = 'lamx';
varyname = 'p_slope';
plotbypc = 1;
colorby_name = 'stdev';


err_flag = 0;
s = jsondecode(fileread('ana.json'));
ndata = size(fieldnames(s), 1);
casenames = fieldnames(s);
if varyname == "p_slope" || varyname == "p_interp"
    ncol = 5;
else
    ncol = 2;
end
x = nan(ndata, 1);
y = nan(ndata, ncol);
colorby = nan(ndata, 1);
for j = 1:ndata
    casename = casenames(j);
    currentcase = s.(casename{:});
    if isfield(currentcase, varxname); x(j) = currentcase.(varxname); end
    if isfield(currentcase, colorby_name); colorby(j) = currentcase.(colorby_name); end
    if isfield(currentcase, varyname); y(j, :) = currentcase.(varyname); end
end
color_order = unique(colorby);
ax = create_tiledlayout(2, 3);

% plot the slope on wavg vs cond plot with different lambda
for i = 1:ncol
    for j = 1:numel(color_order)
        same_color_idx = find(colorby == color_order(j));
        ax(i) = my_scatter(ax(i), 'plot', ['pc = ', num2str((i-1)*1000), ' psi'],...
        x(same_color_idx)', varxname, 'normal', ...
        y(same_color_idx, i)', varyname, 'normal', ...
        10, cc(j, :), num2str(color_order(j)));
    end
    ax(i).XLim = [1, 6];
    % ax(i).YLim = [0.3, 3];
    set(ax(i), 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
    legend(ax(i), 'show')

end


%% external functions
function axes = create_tiledlayout(nrow, ncol)
t = tiledlayout(figure('Color',[1 1 1]), nrow, ncol);
axes = [];
for j = 1:nrow * ncol
    axes = [axes; nexttile(t)];
end
end