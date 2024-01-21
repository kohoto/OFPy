function fig = my_scatter(ax1, plot_type, fig_title, xs, x_label, xlog, ys, y_label, ylog, marker_sizes, colors, disp_names)
%CREATEFIGURE(X1, Y1, Size1, Color1)
%  xs:  vector of scatter x data
%  ys:  vector of scatter y data
%  marker_sizes:  vector of scatter size data
%  colors:  vector of scatter color data
%  disp_names:  vector of scatter color data


% Create axes
% ax1 = axes(fig, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
hold(ax1,'on');
% Create scatter
if plot_type == "box"
    b = boxchart(xs(:)', ys(:)');
    cc = tamu_color();
    b.BoxFaceColor = cc(1, :);
    b.BoxWidth = 0.5 * min(diff(unique(xs)));
    b.MarkerColor = b.BoxFaceColor;
else
    for i = 1:size(disp_names, 1)
        if plot_type == "plot"
            plot(xs(i, :), ys(i, :), '-', 'Color', colors(i, :), 'LineWidth', 1.5, 'DisplayName', '');
            p = plot(xs(i, :), ys(i, :), 'o', 'MarkerSize', marker_sizes(i), 'MarkerFaceColor',colors(i, :), 'DisplayName', disp_names(i), 'LineWidth', 0.5, 'MarkerEdgeColor', 'k');
        elseif plot_type == "scatter"
            p = scatter(xs(i, :), ys(i, :), marker_sizes(i), colors(i, :), 'DisplayName', disp_names(i), 'LineWidth', 0.5, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(i, :));

        end
        dtRows =   [dataTipTextRow('X',xs(i, :)),...
                    dataTipTextRow('Y',ys(i, :)),...
                    dataTipTextRow('Seed',repmat(string(disp_names{i}(5:8)),1,5))];
        p.DataTipTemplate.DataTipRows = dtRows;
        legend(ax1,'show');
    end
end
% Create labels
xlabel(x_label);
ylabel(y_label);
% Create title
title(fig_title);

box(ax1,'on');
hold(ax1,'off');
% Set the remaining axes properties
% set(ax1,'FontName','Segoe UI','GridLineWidth',1,'LineWidth',1,'XGrid',...
%     'on','YGrid','on');
set(ax1, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
set(ax1,'GridLineWidth',1, 'XGrid', 'on', 'YGrid', 'on');
if xlog == "log"
    set(ax1, 'XScale', 'log', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end
if ylog == "log"
    set(ax1, 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end

