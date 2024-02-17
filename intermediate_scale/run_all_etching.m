% provide batch name here!
batch_dir = 'case1-seed4785478';


% Step 1: Create folders named k[1-4][1-4] in a source directory
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\';
start_proj_dir = fullfile(intermCases_dir, ['start_proj_', batch_dir(1:5)]);


% create batch dir
nlam = 4;
nsdv = 4;
mkdir(fullfile(intermCases_dir, batch_dir))
parfor iter=1:nlam*nsdv
    ilam = ceil(iter / nlam);
    isdv = mod(iter / nsdv);
    generate_roughness_under_pc(batch_dir, ilam, isdv) % run Acid_Fracturing.exe.
end

