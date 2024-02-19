close all; clear;
% provide batch name here!
%batch_dir = 'case1-seed4785478';
batch_dir = 'case1-seed1785478_TJ';


% Step 1: Create folders named k[1-4][1-4] in a source directory
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\';
start_proj_dir = fullfile(intermCases_dir, ['start_proj_', batch_dir(1:5)]);


% create batch dir
nlam = 4;
nsdv = 4;
batch_path = fullfile(intermCases_dir, batch_dir);
if ~exist(batch_path, 'dir')
    mkdir(batch_path)
end

%parfor iter=1:nlam*nsdv
for iter=1:nlam*nsdv
    ilam = ceil(iter / nlam);
    isdv = mod(iter, nsdv) + 1;
    generate_roughness_under_pc(batch_dir, ilam, isdv) % run Acid_Fracturing.exe.
end

delete_excess_files_from_acidfrac(batch_path, nlam, nsdv)
delete_execution_files(batch_path, nlam, nsdv)