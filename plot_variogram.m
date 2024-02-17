function ax = plot_variogram(ax, vari_data)
% plot four lines from before/after and top/bottom.
cc = tamu_color();
for timing = fieldnames(vari_data)'
    for position = fieldnames(vari_data.(timing{:}))'
        ax = my_scatter(ax, 'line', '',...
            vari_data.(timing{:}).(position{:}).varx.lag', 'Lag distance [in]', 'normal', ...
            vari_data.(timing{:}).(position{:}).varx.gamma', '\gamma [in]', 'normal', ...
        10, cc((timing{:} == "after") * 2 + 1, :), timing{:}); % bofore is gonna have ligh
        ax.XLim = [0, 7];
    end
end