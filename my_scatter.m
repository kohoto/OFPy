function ax1 = my_scatter(ax1, plot_type, series_name, xs, x_label, xlog, ys, y_label, ylog, marker_sizes, colors, disp_names)
%CREATEFIGURE(X1, Y1, Size1, Color1)
%  xs:  vector of scatter x data
%  ys:  vector of scatter y data
%  marker_sizes:  vector of scatter size data
%  colors:  vector of scatter color data
%  disp_names:  vector of scatter color data

if size(colors, 1) == 1 % if only one color, then use that for all lines.
    colors = repmat(colors, size(disp_names, 1), 1);
end
% Create axes
% ax1 = axes(fig, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
hold(ax1,'on');
% Create scatter
if plot_type == "box"
    b = boxchart(ax1, xs(:)', ys(:)');
    b.BoxFaceColor = colors(1, :);
    b.BoxWidth = 0.5 * min(diff(unique(xs)));
    b.MarkerColor = b.BoxFaceColor;
    b.DisplayName = series_name;
else
    for i = 1:size(disp_names, 1)
        if plot_type == "plot"
            plot(ax1, xs(i, :), ys(i, :), '-', 'Color', colors(i, :), 'LineWidth', 1.5, 'DisplayName', '');
            p = plot(ax1, xs(i, :), ys(i, :), 'o', 'MarkerSize', marker_sizes(i), 'MarkerFaceColor',colors(i, :), 'DisplayName', disp_names(i), 'LineWidth', 0.5, 'MarkerEdgeColor', 'k');
        elseif plot_type == "scatter"
            p = scatter(ax1, xs(i, :), ys(i, :), marker_sizes(i), 'DisplayName', disp_names(i), 'LineWidth', 0.5, 'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :), 'MarkerFaceAlpha', 0.6);

        elseif plot_type == "line"
            plot(ax1, xs(i, :), ys(i, :), '-', 'Color', colors(i, :), 'LineWidth', 1.5, 'DisplayName', '');
        end
        % dtRows =   [dataTipTextRow('X',xs(i, :)),...
        %             dataTipTextRow('Y',ys(i, :)),...
        %             dataTipTextRow('Seed',repmat(string(disp_names{i}(5:8)),1,5))];
        % p.DataTipTemplate.DataTipRows = dtRows;
        title(ax1, series_name);
    end
end
% Create labels
% legend(ax1,'show');
xlabel(ax1, x_label);
ylabel(ax1, y_label);
% Create title

box(ax1,'on');
hold(ax1,'off');
% Set the remaining axes properties
set(ax1, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
set(ax1,'GridLineWidth',1, 'XGrid', 'on', 'YGrid', 'on');
if xlog == "log"
    set(ax1, 'XScale', 'log', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end
if ylog == "log"
    set(ax1, 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end

