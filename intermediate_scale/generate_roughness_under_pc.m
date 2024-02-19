function generate_roughness_under_pc(batch_dir, ilam, isdv)
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\';

case_dir = sprintf('k%d%d', ilam, isdv);
casepath = fullfile(intermCases_dir, batch_dir, case_dir);
destinationFolder = fullfile(intermCases_dir, batch_dir, case_dir, 'etching');

if ~isfile(fullfile(destinationFolder, 'suface1_30.dat')) % prep and run acid frac
    start_proj_dir = fullfile(intermCases_dir, ['start_proj_', batch_dir(1:5)]);
    if ~exist(casepath, 'dir')
        mkdir(casepath);
    end
    if ~exist(fullfile(casepath, 'etching'), 'dir')
        mkdir(fullfile(casepath, 'etching'));
    end
    
    % Step 2: Copy a file that has the same name as the folder name for all folders created in step 1
    sourceFile = fullfile(start_proj_dir, 'ks', [sprintf('permeability%d%d', ilam, isdv), '.dat']);
    destinationFile = fullfile(casepath, 'etching', 'permeability.dat');
    copyfile(sourceFile, destinationFile);
    
    
    % before starts, find all files to copy
    allFiles = dir(fullfile(start_proj_dir, 'etching', '*')); % Get names of all files/folders in 'start_proj' directory
    idx_copy_files = [];
    for ifile = 1:numel(allFiles)
        if ~strcmp(allFiles(ifile).name, 'ks') % Exclude 'ks' folder
            idx_copy_files = [idx_copy_files, ifile];
        end
    end
    
    
    
    % Step 3: Copy all files in start_proj except the folder ks to all folders created in step 1
    
    for ifile = 1:numel(idx_copy_files)
        if allFiles(ifile).name ~= "." || allFiles(ifile).name ~= ".."
            sourceFolder = fullfile(start_proj_dir, 'etching', allFiles(ifile).name);
            copyfile(sourceFolder, destinationFolder);
        end
    end
    
    % Step 4: Execute Acidfrac.exe in each k[1-4][1-4] folder

    cd(destinationFolder); % Change current directory to the folder
    system('Acid_Fracturing.exe'); % Execute Acidfrac.exe
end

Deng_closure_gpt(casepath)
end