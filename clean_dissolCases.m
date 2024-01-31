function clean_dissolCases()



% Specify the parent directory
search_dirs = { ...
    'C:/Users/tohoko.tj/dissolCases', ...
    'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2', ...
    'C:/Users/tohoko.tj/OneDrive - Texas A&M University/Documents/20_Reseach/Simulation/OpenFOAM_results/dissolCases3'};
if time == "all"
    search_dirs(end+1) = {['R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/300s']};
end
search_condition = strrep(['lambda', sprintf('%.1f', lambdax), '-' , sprintf('%.1f', lambday), '-stdev', num2str(stdev)], '.', '_');
% since I sometimes make a mistake on directory naming, I added this search condition.
search_condition2 = strrep(['lambda', sprintf('%i', lambdax), '-' , sprintf('%.1f', lambday), '-stdev', num2str(stdev)], '.', '_');
cases_meet_conditions = [];

% Loop over the searching_dir
for search_dir = search_dirs
    for stdev = {'0_025', '0_05', '0_075', '0_1'}
        stdev_dir_name = [search_dir{1}, '/stdev', stdev{1}];
        if isfolder(stdev_dir_name)

            % Get a list of all files and folders in this folder
            seed_dir_names = get_folder_names(stdev_dir_name);
            for k = 1 : length(seed_dir_names)
                % Get the subfolders in the second level
                lambda_dir_names = get_folder_names(fullfile(stdev_dir_name, seed_dir_names(k).name));
                % Loop over the subfolders in the second level
                for j = 1 : length(lambda_dir_names)
                    % get conductivity and etching folders
                    run_dir_names = get_folder_names(fullfile(stdev_dir_name, seed_dir_names(k).name, lambda_dir_names(j).name));
                    for l = 1 : length(run_dir_names)
                        files = dir('core.*');
                        for m = 1:length(files)
                            delete(files(m).name);
                        end
                    end
                    % Loop over the files and delete each one

                end
            end
        end
    end
end
end