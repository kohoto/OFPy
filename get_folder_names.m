function sub_folders = get_folder_names(parent_folder)
all_files = dir(parent_folder);

% Extract only those that are directories.
dirFlags = [all_files.isdir] & ~strcmp({all_files.name},'.') & ~strcmp({all_files.name},'..');
sub_folders = all_files(dirFlags);
end