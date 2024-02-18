function ax = add_ndata_on_plot(ax, n, x_ratio, y_ratio)
% x coordinate of the text
% y coordinate of the text
hold(ax, 'on');
x = ax.XLim(1) + (ax.XLim(2) - ax.XLim(1)) * x_ratio; % 0 is left, 1 is right
y = ax.YLim(1) + (ax.YLim(2) - ax.YLim(1)) * y_ratio; % 0 is btm, 1 is top

if isinteger(n)
    text(ax, x, y, ['n = ', num2str(n)]); %, ...
% 'FitBoxToText', 'on', ...
% 'BackgroundColor', 'white', ...
% 'EdgeColor', 'black');
else
    text(ax, x, y, sprintf("R^{2} = %.2f", n));
end