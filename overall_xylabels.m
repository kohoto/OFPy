function axes = overall_xylabels(axes, xname, yname)
for i = 1:numel(axes)
    xlabel(axes(i), ''); % removing xylabels for indivisual plots
    ylabel(axes(i), '');
end
t = ancestor(axes(1), 'tiledlayout');
xlabel(t, xname, 'Interpreter', 'latex');
ylabel(t, yname, 'Interpreter', 'latex');
end