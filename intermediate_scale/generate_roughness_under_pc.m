function generate_roughness_under_pc(batch_dir, ilam, isdv)
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\';
start_proj_dir = fullfile(intermCases_dir, ['start_proj_', batch_dir(1:5)]);

case_dir = sprintf('k%d%d', ilam, isdv);
casepath = fullfile(intermCases_dir, batch_dir, case_dir);
mkdir(casepath);
mkdir(fullfile(casepath, 'etching'));
% Step 2: Copy a file that has the same name as the folder name for all folders created in step 1
sourceFile = fullfile(start_proj_dir, 'ks', [sprintf('permeability%d%d', ilam, isdv), '.dat']);
destinationFile = fullfile(casepath, 'etching', 'permeability.dat');
copyfile(sourceFile, destinationFile);


% before starts, find all files to copy
allFiles = dir(fullfile(start_proj_dir, '*')); % Get names of all files/folders in 'start_proj' directory
idx_copy_files = [];
for ifile = 1:numel(allFiles)
    if ~strcmp(allFiles(ifile).name, 'ks') % Exclude 'ks' folder
        idx_copy_files = [idx_copy_files, ifile];
    end
end



% Step 3: Copy all files in start_proj except the folder ks to all folders created in step 1
destinationFolder = fullfile(intermCases_dir, batch_dir, case_dir, 'etching');
for ifile = numel(idx_copy_files)
    sourceFolder = fullfile(start_proj_dir, allFiles(ifile).name);
    copyfile(sourceFolder, destinationFolder);
end

% Step 4: Execute Acidfrac.exe in each k[1-4][1-4] folder
cd(destinationFolder); % Change current directory to the folder
system('Acid_Fracturing.exe'); % Execute Acidfrac.exe

%% delete excess output files from Acid_Fracturing
% Define the folder path

% List all files in the folder
files_to_delete = [dir(fullfile(casepath, 'result*.dat')); ...
    dir(fullfile(casepath, 'suface1_0*.dat')); ...
    dir(fullfile(casepath, 'suface1_1*.dat')); ...
    dir(fullfile(casepath, 'suface1_2*.dat')); ...
    dir(fullfile(casepath, 'surface2_*.dat')); ...
    dir(fullfile(casepath, 'Surface*.dat'))];


% Loop through the files and delete them
for ifile = 1:length(files_to_delete)
    delete(fullfile(casepath, files_to_delete(ifile).name));
end

Deng_closure_gpt(casepath)
end