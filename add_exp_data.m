function [dataStruct, err_cases] = add_exp_data(dataStruct, file_name)
% this is to create the data struct using json files.

parent_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\Experiment\0_profilometer\Tohoko';
sub_folders = get_folder_names(parent_dir);
err_cases = [];

for j = 1 : length(sub_folders)
    json_file_path = fullfile(parent_dir, sub_folders(j).name, file_name);
    if isfile(json_file_path)
        [dataStruct, err_flag] = store_batch_json(dataStruct, file_name, fullfile(parent_dir, sub_folders(j).name));
        if err_flag >= 1
            err_cases = [err_cases; json_file_path, err_flag];
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