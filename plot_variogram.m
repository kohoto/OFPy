function ax = plot_variogram(ax, vari_data)
% plot four lines from before/after and top/bottom.
cc = tamu_color();
for timing = fieldnames(vari_data)'
    for position = fieldnames(vari_data.(timing{:}))'
        ax = my_scatter(ax, 'line', 'Variogram',...
            vari_data.(timing{:}).(position{:}).varx.lag', 'Lag [in]', 'normal', ...
            vari_data.(timing{:}).(position{:}).varx.gamma', 'gamma [in]', 'normal', ...
        10, cc((timing{:} == "after") + 1, :), timing{:});
    end
end