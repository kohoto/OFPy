function axes = create_tiledlayout(nrow, ncol, height_ratio)
% height_ratio: ratio to the full height of letter size paper contents area in my thesis
figure_width = (8.5 - 1.4 - 1.15) * 1; % inch
figure_height = ((11 - 1.25 - 1.25) * height_ratio - 0.5) * 1; % 1 inch for fig title, doubling it just because it looks so small on screen

t = tiledlayout(figure('Color',[1 1 1], 'Visible', 'off', 'Units', 'inches', 'Position', [1, 0, figure_width, figure_height]), nrow, ncol, 'Padding', 'compact');
axes = [];
for irow = 1:nrow
    ax_row = [];
    for icol = 1:ncol
        ax_row = [ax_row, nexttile(t)];
    end
    axes = [axes; ax_row];
end

for i = 1:numel(axes)
    axes(i) = my_plot_format(axes(i));
end