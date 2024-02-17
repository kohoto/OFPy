function create_all_perm_files()
lambda_dx = [0.1, 0.3, 0.5, 0.7, 0.9];
lambda_dz = 0.1;
stdev = [0.1, 0.3, 0.5, 0.7, 0.9];
k_avg = 0.1;
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\';
ks_dir = fullfile(intermCases_dir, 'start_proj_case1', 'ks');
indat_path = 'in.dat';


for ilam = 1:4
    for isdv = 1:4
        %% read and modify in.dat
        fileID = fopen(fullfile(ks_dir, indat_path), 'r');
        fileContent = textscan(fileID, '%s', 'Delimiter', '\n');
        fileContent = fileContent{1}; % Convert from cell array to string array
        fclose(fileID);
        
        % Replace the numbers in the lines
        for i = 5:6
            lineParts = strsplit(fileContent{i});
            lineParts{1} = num2str(k_avg); % Update the first number
            fileContent{i} = strjoin(lineParts); % Join the parts back to form the line
        end
        for i = 7:8
            lineParts = strsplit(fileContent{i});
            lineParts{1} = num2str(stdev(isdv)); % Update the first number
            fileContent{i} = strjoin(lineParts); % Join the parts back to form the line
        end
        % overwrite in.dat. Copy the same contents to in[1-4][1-4].dat
        fileID = fopen(indat_path, 'w');
        fprintf(fileID, '%s\n', fileContent{:});
        fclose(fileID);
        copyfile(fullfile(ks_dir, indat_path), fullfile(ks_dir, sprintf('in%d%d.dat', ilam, isdv)));
        create_permeability_gpt(ks_dir, lambda_dx(ilam), lambda_dz)
        % copy output permeability.dat file to permeability[1-4][1-4].dat
        copyfile(fullfile(ks_dir, 'permeability.dat'), fullfile(ks_dir, sprintf('permeability%d%d.dat', ilam, isdv)));
    end
end
end