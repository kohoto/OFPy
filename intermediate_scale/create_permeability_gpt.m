function create_permeability_gpt(sgsimpath, lambda_dx, lambda_dz)
a_hmax = lambda_dx * 256;
a_hmin = lambda_dz * 256;

write_sgsim_par_permeability(sgsimpath, a_hmax, a_hmin)

% Run the executable file
intermCases_dir = 'C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\MouDeng\';
cd(fullfile(intermCases_dir, 'start_proj_case1', 'ks')); % Change current directory to the folder
system('sgsim.exe'); % Execute Acidfrac.exe

% Open the input.dat file for reading
fid = fopen(fullfile(sgsimpath, 'in.dat'), 'r');

% Read the data using textscan
data = textscan(fid, '%f %*[^\n]');

fclose(fid);
% data = read_input_dat(casepath);

% Extract the variables from the read data
L = data{1}(1);
H = data{1}(2);
NX = data{1}(3);
NZ = data{1}(4);
avg_perm_Lims = data{1}(5);
avg_perm_Dolo = data{1}(6);
SD_Lims = data{1}(7);
SD_Dolo = data{1}(8);

% Calculate DeltaX and DeltaZ
DeltaX = L / (NX - 1);
DeltaZ = H / (NZ - 1);
% Allocate memory for arrays
nRow = zeros(1, NX * NZ);
nCol = zeros(1, NX * NZ);
% KnownPerm = zeros(1, NX * NZ);
perm = zeros(NZ, NX);

% % Read rawdata.dat
% rawdata = importdata('rawdata.dat');
% Num = size(rawdata, 1);
% for i = 1:Num
%     temp1 = rawdata(i, 1);
%     temp2 = rawdata(i, 2);
%     temp3 = rawdata(i, 3);
%     nCol(i) = fix((temp1 - DeltaX / 2) / DeltaX);
%     nRow(i) = fix((temp2 - DeltaZ / 2) / DeltaZ + 0.2);
%     KnownPerm(i) = exp(log(avg_perm_Lims) + SD_Lims * log(avg_perm_Lims) * temp3);
%     if avg_perm_Lims == 1
%         KnownPerm(i) = exp(log(avg_perm_Lims) + SD_Lims * log(10) * temp3);
%     end
% end

% Read mineralogy.dat
%mineralogy_data = importdata(fullfile(casepath, 'mineralogy.dat'));
% Open the input.dat file for reading
fid = fopen(fullfile(sgsimpath, 'mineralogy.dat'), 'r');

% Read the data using textscan
mineralogy = textscan(fid, '%f %f %f %*[^\n]', 'HeaderLines', 8);
mineralogy = mineralogy(:, 1);
mineralogy = mineralogy{:};
mineralogy = reshape(mineralogy, [NZ, NX]);
fclose(fid);

% Read 1.out
fid = fopen(fullfile(sgsimpath, '1.out'), 'r');

% Read the data using textscan
random_data = textscan(fid, '%f %*[^\n]', 'HeaderLines', 3);
random_data = random_data{:};
fclose(fid);
%random_data = importdata(fullfile(casepath, '1.out'));

% Calculate perm array
for k = 1:NZ
    for i = 1:NX
        temp1 = random_data((k - 1) * NX + i);
        if mineralogy(k, i) == 1
            avg = log(avg_perm_Lims);
            SD = abs(avg) * SD_Lims;
            if avg_perm_Lims == 1
                SD = log(10) * SD_Lims;
            end
        else
            avg = log(avg_perm_Dolo);
            SD = abs(avg) * SD_Dolo;
            if avg_perm_Lims == 1
                SD = log(10) * SD_Dolo;
            end
        end
        temp2 = avg + SD * temp1;
        perm(k, i) = exp(temp2);
        if perm(k, i) < 0
            perm(k, i) = 0;
        end
    end
end

% Replace KnownPerm values in perm array
% for i = 1:Num
%     perm(nRow(i), nCol(i)) = KnownPerm(i);
% end

% Write permeability.dat
fp3 = fopen(fullfile(sgsimpath, 'permeability.dat'), 'w+');
fprintf(fp3, 'TITLE\t= "permeability"\n');
fprintf(fp3, 'VARIABLES = "x (feet)"\n');
fprintf(fp3, '"z (feet)"\n');
fprintf(fp3, '"k (md)"\n');
fprintf(fp3, 'ZONE T="Data"\n');
fprintf(fp3, 'I=%d, J=%d ZONETYPE=Ordered\n', NX, NZ);
fprintf(fp3, 'DATAPACKING=POINT\n');
fprintf(fp3, 'DT=(SINGLE SINGLE SINGLE )\n');

for k = 1:NZ
    for i = 1:NX
        fprintf(fp3, '%f %f %f \n', (i - 1) * DeltaX, (k - 1) * DeltaZ, perm(k, i));
    end
end
fclose(fp3);
