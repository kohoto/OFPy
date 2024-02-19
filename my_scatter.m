function ax = my_scatter(ax, plot_type, series_name, xs, x_label, xlog, ys, y_label, ylog, marker_sizes, colors, disp_names)
%CREATEFIGURE(X1, Y1, Size1, Color1)
%  xs:  vector of scatter x data
%  ys:  vector of scatter y data
%  marker_sizes:  vector of scatter size data
%  colors:  vector of scatter color data
%  disp_names:  vector of scatter color data

if size(colors, 1) == 1 % if only one color, then use that for all lines.
    colors = repmat(colors, size(xs, 1), 1);
end


if plot_type == "errorbar"
    delta = marker_sizes;
    marker_sizes = 12;
end

if size(marker_sizes, 1) == 1 % if only one color, then use that for all lines.
    marker_sizes = repmat(marker_sizes, size(xs, 1), 1);
end

% Create axes
% ax1 = axes(fig, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
hold(ax,'on');
% Create scatter
if plot_type == "box"
    b = boxchart(ax, xs(:)', ys(:)');
    b.BoxFaceColor = colors(1, :);
    b.BoxWidth = 0.5 * min(diff(unique(xs)));
    b.MarkerColor = b.BoxFaceColor;
    b.DisplayName = series_name;
else
    for i = 1:size(xs, 1)
        if plot_type == "errorbar"
            erryp = delta(1) * ones(1, size(xs,2));
            erryn = delta(2) * ones(1, size(xs,2));
            hError = errorbar(ax, xs(i, :), ys(i, :), erryp, erryn, 'LineStyle', 'none', 'Color', colors(i, :), 'Marker', 'none');
        end
        if plot_type == "plot" || endsWith(plot_type, "line")
            p = plot(ax, xs(i, :), ys(i, :), '-', 'Color', colors(i, :), 'LineWidth', 1.5, 'DisplayName', '');
        end
        if plot_type == "plot" || plot_type == "scatter" || plot_type == "errorbar"
            p = scatter(ax, xs(i, :), ys(i, :), marker_sizes(i), 'DisplayName', disp_names(i, :), 'LineWidth', 0.1, 'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :), 'MarkerFaceAlpha', 0.5);
        end

        if startsWith(plot_type, "alpha")
            p.Color = [colors(i, :), 0.5];
        end
        % dtRows =   [dataTipTextRow('X',xs(i, :)),...
        %             dataTipTextRow('Y',ys(i, :)),...
        %             dataTipTextRow('Seed',repmat(string(disp_names{i}(5:8)),1,5))];
        % p.DataTipTemplate.DataTipRows = dtRows;
    end
end
% Create title

box(ax,'on');
hold(ax,'off');
% Set the remaining axes properties
ax = my_plot_format(ax);
title(ax, series_name, 'Interpreter', 'latex');
xlabel(ax, x_label, 'Interpreter', 'latex');
ylabel(ax, y_label, 'Interpreter', 'latex');
