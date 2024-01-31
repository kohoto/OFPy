function write_cond_json()
clear; close all;
proj_name = 'acidfrac10_rough';
expCases_path = fullfile('C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\20_Reseach\Experiment\0_profilometer\Tohoko', proj_name);

lambdax = [1.0, 2.0, 4.0, 6.0];
lambday = [1.0]; % must be only one number to fit all plots in figuress.
stdev = [0.025, 0.05, 0.075, 0.1];
file_name = 'cond.json';
colored_by = 'lambda_x__in';
sized_by = 'wid_e__in';

n1 = numel(lambdax);
n2 = numel(lambday);
n3 = numel(stdev);

% load other info in excel sheet
t = store_exp_var_from_excel();

% construct 
    % if variogram.json exist, do the following
jsonFile = fullfile(expCases_path, 'variogram.json');
if isfile(jsonFile)
    vari_exp = jsondecode(fileread(jsonFile));
    ax = create_tiledlayout(1, 1);  
    ax = plot_variogram(ax, vari_exp);
    lamx = input('Please enter lambdax: ');
    t_case = t(t.ProfilometerFileName==string(proj_name), :);
    d = struct();
    d.lambda_x__in = lamx;
    d.lambda_y__in = 1.0;
    d.stdev = unique(t_case.Value_stdev);
    d.etched_vol__in3 = unique(t_case.Value_etched_vol);
    d.wid_e__in = unique(t_case.Value_etched_vol) ./ (7 * 1.7 * 2);
    d.pc = t_case.Pc_psi;
    d.cond = t_case.kfw_mdft;
    
    % Write the JSON-formatted text to a file
    fid = fopen(fullfile(expCases_path, 'cond.json'), 'w');
    if fid == -1, error('Cannot create JSON file'); end
    fwrite(fid, jsonencode(d, 'PrettyPrint', true), 'char');
    fclose(fid);
end
end
