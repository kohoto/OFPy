% run_all_intermediate
casepath = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\case1\cl0_005\case1-cl0_005-m00-k01\k02';
lambda_dx = 0.5;
lambda_dz = 0.25;

%create_permeability_gpt(casepath, lambda_dx, lambda_dz)
% % Run the executable file
% status = system(['"', fullfile(casepath, 'Acid_Fracturing.exe'), '"']);
% % Check if the execution was successful
% if status ~= 0
%     disp('Error running Acid_Fracturing.exe.');
% end

%% delete excess output files from Acid_Fracturing
% Define the folder path

% List all files in the folder
files = dir(fullfile(casepath, 'result*.dat'));
files = [files; dir(fullfile(casepath, 'suface1_0*.dat'))];
files = [files; dir(fullfile(casepath, 'suface1_1*.dat'))];
files = [files; dir(fullfile(casepath, 'suface1_2*.dat'))];
files = [files; dir(fullfile(casepath, 'surface2_*.dat'))];
files = [files; dir(fullfile(casepath, 'Surface*.dat'))];
 

% Loop through the files and delete them
for i = 1:length(files)
    filepath = fullfile(casepath, files(i).name);
    delete(filepath);
end

Deng_closure_gpt(casepath)