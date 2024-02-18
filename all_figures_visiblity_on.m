function all_figures_visiblity_on()
allFigures = findall(0, 'Type', 'figure');
% Loop through all figures and set them to visible
for fig = allFigures'
    fig.Visible = 'on';
end
end