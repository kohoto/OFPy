function cases_meet_conditions = find_cases_from_conditions(lambdax, lambday, stdev)
% Specify the parent directory
parent_dir = 'C:/Users/tohoko.tj/dissolCases/';
search_condition = strrep(['lambda', sprintf('%.1f', lambdax), '-' , sprintf('%.1f', lambday), '-stdev', num2str(stdev)], '.', '_');
% Get a list of all files and folders in this folder

subFolders = get_folder_names(parent_dir);

% Print folder names to command window.
cases_meet_conditions = [];
for k = 1 : length(subFolders)
    % Get the subfolders in the second level
    level2_subFolders = get_folder_names(fullfile(parent_dir, subFolders(k).name));
    % Loop over the subfolders in the second level
    for j = 1 : length(level2_subFolders)
        if strcmp(level2_subFolders(j).name, search_condition)
            cases_meet_conditions = [cases_meet_conditions, string(fullfile(parent_dir, subFolders(k).name, level2_subFolders(j).name))];
        end
    end
end
end

function sub_folders = get_folder_names(parent_folder)
all_files = dir(parent_folder);

% Extract only those that are directories.
dirFlags = [all_files.isdir] & ~strcmp({all_files.name},'.') & ~strcmp({all_files.name},'..');
sub_folders = all_files(dirFlags);
end