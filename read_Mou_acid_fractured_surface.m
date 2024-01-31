% Set up the Import Options and import the data
clear; close all;
opts = delimitedTextImportOptions("NumVariables", 4);

% Specify range and delimiter
opts.DataLines = [11, Inf];
opts.Delimiter = " ";

% Specify column names and types
opts.VariableNames = ["x_ft", "z_ft", "y_mm", "k_md"];
opts.VariableTypes = repmat(["double"], 1, 4);

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";

% Specify variable properties
opts = setvaropts(opts, "x_ft", "TrimNonNumeric", true);
opts = setvaropts(opts, "x_ft", "ThousandsSeparator", ",");

% Import the data
d = readtable("C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\30_Codes\Jianye Mou code\Upload acid frac\acid fracturing\MinePerm_Result\surface2_30.dat", opts);
clear opts

% Display results
nx = 64;
nz = 64;
ny = 4;

reshape_vec = [nx, nz];
s = struct();
for fi = d.Properties.VariableNames
    disp(['working on ', fi{:}])
    s.(fi{:}) = reshape(d.(fi{:}), reshape_vec);
end

ax = create_tiledlayout(1, 1);
contourf(ax, s.x_ft(2:end-1, 2:end-1), ...
    s.z_ft(2:end-1, 2:end-1), ...
    - s.y_mm(2:end-1, 2:end-1) .* 0.0393701, 'EdgeColor', 'none'); % since the data is depth from y=0, I flipped sign.



%% overall formatting
% Set colormap and color limits for all subplots
axis(ax, 'equal')
xlabel(ax, 'x [ft]');
ylabel(ax, 'z [ft]');
ax.XLim = [0, 10];
ax.YLim = [0, 10];
%set(ax, 'Colormap', turbo, 'CLim', [-Inf, max_width]);
set(ax, 'Colormap', turbo, 'CLim', [-Inf, Inf]);
set(ax, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
box(ax,'on');
% Assign color bar to one tile
cbh = colorbar(ax(1));

% Position the colorbar as a global colorbar representing all tiles
cbh.Layout.Tile = 'east';
cbh.Label.String = 'width [in]';
set(cbh, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
box(cbh,'on');
