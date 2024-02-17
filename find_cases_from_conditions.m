function cases_meet_conditions = find_cases_from_conditions(lambdax, lambday, stdev, time)
% time: etching time
% Specify the parent directory
search_dirs = { ...
    'C:/Users/tohoko.tj/dissolCases', ...
    'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/600s', ...
    'C:/Users/tohoko.tj/OneDrive - Texas A&M University/Documents/20_Reseach/Simulation/OpenFOAM_results/dissolCases3'};
if time == "all"
    search_dirs(end+1:end+4) = { ...
        'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/200s', ...
        'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/300s', ...
        'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/400s', ...
        'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/500s', ...
        };
end
search_condition = strrep(['lambda', sprintf('%.1f', lambdax), '-' , sprintf('%.1f', lambday), '-stdev', num2str(stdev)], '.', '_');
% since I sometimes make a mistake on directory naming, I added this search condition.
search_condition2 = strrep(['lambda', sprintf('%i', lambdax), '-' , sprintf('%.1f', lambday), '-stdev', num2str(stdev)], '.', '_');
cases_meet_conditions = [];

% Loop over the searching_dir
for search_dir = search_dirs
    stdev = strrep(num2str(stdev), '.', '_');
    stdev_dir_name = [search_dir{1}, '/stdev', stdev];
    if isfolder(stdev_dir_name)

        % Get a list of all files and folders in this folder
        subFolders = get_folder_names(stdev_dir_name);
        for k = 1 : length(subFolders)
            % Get the subfolders in the second level
            level2_subFolders = get_folder_names(fullfile(stdev_dir_name, subFolders(k).name));
            % Loop over the subfolders in the second level
            for j = 1 : length(level2_subFolders)
                if strcmp(level2_subFolders(j).name, search_condition) || strcmp(level2_subFolders(j).name, search_condition2)
                    cases_meet_conditions = [cases_meet_conditions, string(fullfile(stdev_dir_name, subFolders(k).name, level2_subFolders(j).name))];
                end
            end
        end
    end

end
end

