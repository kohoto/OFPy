function plot_width_distribution()
clear; close all;


cases = ["R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/stdev0_1/seed0100-stdev0_1/lambda6_0-1_0-stdev0_1"];

pc = 1000:1000:4000;
for c_path = cases

    ax = create_tiledlayout(2, 2);
    max_width = 0;
    for i = 1:numel(pc)
        pointsFile = fullfile(c_path, ['conductivity', num2str(pc(i))], 'constant/polyMesh/points');
        if isfile(pointsFile)
            d = read_points(pointsFile);
            %ax(i) = surf(ax(i), d.x(:, :, 1), d.y(:, :, 1), d.z(:, :, end) - d.z(:, :, 1), 'EdgeColor', 'none', 'jet');
           
            contourf(ax(i), d.x, d.y, d.z, 'EdgeColor', 'none');
            if max_width < max(d.z(:))
                max_width = max(d.z(:));
            end
        end
    end
end

%% formatting plots
for i = 1:numel(ax)
    ax(i).Title.String = ['P_{c} = ' num2str((i)*1000), ' psi'];
end

%% overall formatting
% Set colormap and color limits for all subplots
axis(ax, 'equal')
xlabel(ax, 'x [in]');
ylabel(ax, 'y [in]');
set(ax, 'XLim', [0, 7], 'YLim', [0, 1.7]);
%set(ax, 'Colormap', turbo, 'CLim', [-Inf, max_width]);
set(ax, 'Colormap', turbo, 'CLim', [-Inf, 0.03]);
set(ax, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
box(ax,'on');
% Assign color bar to one tile
cbh = colorbar(ax(1));

% Position the colorbar as a global colorbar representing all tiles
cbh.Layout.Tile = 'east';
cbh.Label.String = 'Width [in]';
set(cbh, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
box(cbh,'on');
end

%% external functions
function d = read_points(pointFile)
wid_threshold = 3.28914e-6; % [m]
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = [21, Inf];
opts.Delimiter = " ";

% Specify column names and types
opts.VariableNames = ["x", "y", "z"];
opts.VariableTypes = ["double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "skip";
opts.LeadingDelimitersRule = "ignore";

% Specify variable properties
opts = setvaropts(opts, ["x", "y", "z"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["x", "y", "z"], "ThousandsSeparator", ",");

% Import the data
points = rmmissing(readtable(pointFile, opts));
d = struct();
nx = numel(unique(points.x));
ny = numel(unique(points.y));
nz = size(points, 1) / (nx * ny);

d.x = reshape(points.x, [nx, ny, nz]);
d.y = reshape(points.y, [nx, ny, nz]);
d.z = reshape(points.z, [nx, ny, nz]);

d.x = d.x(:, :, 1) .* 39.3701;
d.y = d.y(:, :, 1) .* 39.3701;

d.z = d.z(:, :, end) - d.z(:, :, 1);
d.z(d.z <= wid_threshold) = NaN;
d.z = d.z .* 39.3701;
end