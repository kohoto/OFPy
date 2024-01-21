clear; close all;
cc = tamu_color();
stdev_max = 0.15;
dissolCasesDir = 'C:/Users/tohoko.tj/dissolCases/';
projName = 'seed6000-stdev0_025';
file_name = 'roughness';


% Get a list of all files and folders in this directory
dirPath = [dissolCasesDir, projName];
allFiles = dir(dirPath);

% Extract only those that are directories
dirFlags = [allFiles.isdir];

% Get a list of all folders
subFolders = allFiles(dirFlags);

% Initialize an empty struct to store the data
dataStruct = struct();
firstTime = 0;
% Loop over each subfolder
for k = 1 : length(subFolders)
    % Ignore '.' and '..' directories
    if ~strcmp(subFolders(k).name, '.') && ~strcmp(subFolders(k).name, '..')
        % Open the file
        fid = fopen(fullfile(dirPath, subFolders(k).name, file_name), 'r');
        
        % Read the header lines
        headerLines = cell(3, 1);
        for i = 1:3
            headerLines{i} = fgetl(fid);
        end

        if firstTime == 0
            headerData = str2num(headerLines{2}); % ignore the warning. Works only with str2num
            nx = headerData(2);
            ny = headerData(3);
            dx = headerData(8);
        end
        tstdev = str2double(strrep(projName(end-4:end),'_', '.'));
        % Read the rest of the data
        roughnessData = fscanf(fid, '%f');
        % Close the file
        fclose(fid);
        % affine distribution correction reimplemented in Python with numpy methods
        m = mean(roughnessData);
        stdev = std(roughnessData);
        dataStruct.(strrep(subFolders(k).name, '-', '__')).stdev = tstdev;
        roughnessData = (tstdev / stdev) * (roughnessData - m);
        dataStruct.(strrep(subFolders(k).name, '-', '__')).roughness = reshape(roughnessData, nx, ny)';
    end
end

% select which ones to plot


% Loop over each field

fields = fieldnames(dataStruct);
bin_centers = NaN(numel(fields), nx * ny);
counts = NaN(numel(fields), nx * ny);
marker_sizes= 6 * ones(numel(fields), 1);
colors = cc(mod([1:numel(fields)], size(cc, 1)) + 1, :);
disp_names = string(fields);

for i = 1:numel(fields)
    % Calculate the PDF using histogram and normalize it
    [cnts, edges] = histcounts(dataStruct.(fields{i}).roughness, 'Normalization', 'pdf');
    counts(i, 1:numel(cnts)) = cnts;
    bin_centers(i, 1:numel(cnts)) = (edges(1:end-1) + edges(2:end)) / 2;
    
    % Plot the PDF using a simple plot with markers and a line
    tstdev = dataStruct.(fields{i}).stdev;
    colors(i, :) = (tstdev / stdev_max) * ones(1, 3);
end



fig = my_scatter('plot', 'Probability Density Function (PDF)',...
    bin_centers, 'Data Values', 'normal', ...
    counts, 'Probability Density', 'normal', ...
    marker_sizes, colors, disp_names);


