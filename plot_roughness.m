clear; close all;
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
        roughnessData = (tstdev / stdev) * (roughnessData - m);
        dataStruct.(strrep(subFolders(k).name, '-', '__')) = reshape(roughnessData, nx, ny)';
    end
end

% select which ones to plot


% Loop over each field
figure;
fields = fieldnames(dataStruct);
for i = 1:numel(fields)
    % Get the field name
    proj_data = fields{i};
    pcolor(repmat([0:dx:(nx-1)*dx], ny, 1), ...
            repmat([0:dx:(ny-1)*dx]', 1, nx), ...
            dataStruct.(proj_data)); 
    % format plot
    shading interp;
    daspect([1 1 1]);
    xlabel('x [in]');
    ylabel('y [in]')
end


