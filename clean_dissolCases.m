function clean_dissolCases()



% Specify the parent directory
search_dirs = { ...
    'C:/Users/tohoko.tj/dissolCases', ...
    'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2', ...
    'C:/Users/tohoko.tj/OneDrive - Texas A&M University/Documents/20_Reseach/Simulation/OpenFOAM_results/dissolCases3',...
    'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/300s'};

% Loop over the searching_dir
for search_dir = search_dirs
    for stdev = {'0_025', '0_05', '0_075', '0_1'}
        stdev_dir_name = [search_dir{1}, '/stdev', stdev{1}];
        if isfolder(stdev_dir_name)

            % Get a list of all files and folders in this folder
            seed_dir_names = get_folder_names(stdev_dir_name);
            for k = 1 : length(seed_dir_names)
                files = dir(fullfile(stdev_dir_name, seed_dir_names(k).name, '*.log'));
                for m = 1:length(files)
                    delete(fullfile(files(m).folder, files(m).name));
                end
                % Get the subfolders in the second level
                lambda_dir_names = get_folder_names(fullfile(stdev_dir_name, seed_dir_names(k).name));
                % Loop over the subfolders in the second level
                for j = 1 : length(lambda_dir_names)
                    % get conductivity and etching folders
                    batch_dirpath = fullfile(stdev_dir_name, seed_dir_names(k).name);
                    rename_case_lambdas(batch_dirpath)
                    run_dir_names = get_folder_names(fullfile(batch_dirpath, lambda_dir_names(j).name));
                    
                    for l = 1 : length(run_dir_names)
                        files = dir(fullfile(stdev_dir_name, seed_dir_names(k).name, 'core*'));
                        for m = 1:length(files)
                            delete(fullfile(files(m).folder, files(m).name));
                        end
                        files = dir(fullfile(stdev_dir_name, seed_dir_names(k).name, 'log*'));
                        for m = 1:length(files)
                            delete(fullfile(files(m).folder, files(m).name));
                        end
                    end
                    % Loop over the files and delete each one

                end
            end
        end
    end
end
end

function rename_case_lambdas(batch_dirpath)
subFolders = get_folder_names(batch_dirpath);
for icase = 1:numel(subFolders)
    % Check if the name of the folder is '11'
    if strcmp(subFolders(icase).name(8), '-')
        % Get the full path of the folder
        oldFolderName = fullfile(batch_dirpath, subFolders(icase).name);
        % Create the new folder name
        newFolderName = fullfile(batch_dirpath, [subFolders(icase).name(1:7), '_0', subFolders(icase).name(8:end)]);
        % Rename the folder
        movefile(oldFolderName, newFolderName);
    end
end
end