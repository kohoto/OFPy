function plot_width_distribution()
clear; close all;


dissolCasesDir = 'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2';
seed = '0101';
stdev_dirs = ["stdev0_025", "stdev0_1"];
file_name = 'roughness';


ax = create_tiledlayout(4, numel(stdev_dirs));

% Initialize an empty struct to store the data
dataStruct = struct();
firstTime = 0;
for istdev = 1:numel(stdev_dirs)
    batch_dir_name = ['seed', seed, '-', char(stdev_dirs(istdev))];
    dirPath = fullfile(dissolCasesDir, char(stdev_dirs(istdev)), batch_dir_name);
    subFolders = get_folder_names(dirPath);
    for icase = 1:numel(subFolders)
        % Check if the name of the folder is '11'
        if strcmp(subFolders(icase).name(8), '-')
            % Get the full path of the folder
            oldFolderName = fullfile(dirPath, subFolders(icase).name);
            % Create the new folder name
            newFolderName = fullfile(dirPath, [subFolders(icase).name(1:7), '_0', subFolders(icase).name(8:end)]);
            % Rename the folder
            movefile(oldFolderName, newFolderName);
        end
    end
    % get modified subfolder names
    subFolders = get_folder_names(dirPath);
    for icase = 1:numel(subFolders)

        roughnessFile = fullfile(dirPath, subFolders(icase).name, file_name);
        if isfile(roughnessFile)
            fid = fopen(roughnessFile, 'r');
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
            % get true standard deviation for affine transformation
            a = stdev_dirs(istdev);
            tstdev = str2double(strrep(a{:}(6:end),'_', '.'));
            % Read the rest of the data
            roughnessData = fscanf(fid, '%f');
            % Close the file
            fclose(fid);
            % affine distribution correction reimplemented in Python with numpy methods
            m = mean(roughnessData);
            stdev = std(roughnessData);
            roughnessData = (tstdev / stdev) * (roughnessData - m);

            contourf(ax(icase, istdev), repmat([0:dx:(nx-1)*dx], ny, 1), ...
                repmat([0:dx:(ny-1)*dx]', 1, nx), ...
                reshape(roughnessData, nx, ny)', 'EdgeColor', 'none');
        end
    end
end
%% formatting plots
% for istdev = 1:numel(stdev_dirs)
%     dirPath = fullfile(dissolCasesDir, stdev_dirs(istdev));
%     subFolders = get_folder_names(dirPath);
%     for icase = 1:numel(subFolders)
%         ax(icase, istdev).Title.String = [stdev_dirs(istdev), ' ', subFolders(icase).name{:}];
%     end
% end
%% overall formatting
% Set colormap and color limits for all subplots
axis(ax, 'equal')
xlabel(ax, 'x [in]');
ylabel(ax, 'y [in]');
set(ax, 'XLim', [0, 7], 'YLim', [0, 1.7]);
%set(ax, 'Colormap', turbo, 'CLim', [-Inf, max_width]);
set(ax, 'Colormap', turbo, 'CLim', [-Inf, Inf]);
set(ax, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
box(ax,'on');
% Assign color bar to one tile
cbh = colorbar(ax(1));

% Position the colorbar as a global colorbar representing all tiles
cbh.Layout.Tile = 'east';
cbh.Label.String = 'Asperities [in]';
set(cbh, 'FontName', 'Segoe UI', 'FontSize', 11, 'LineWidth', 1);
box(cbh,'on');

