% Set up the Import Options and import the data
opts2 = spreadsheetImportOptions("NumVariables", 4);

% Specify sheet and range
opts2.Sheet = "ExpData";
opts2.DataRange = "A2:D525";

% Specify column names and types
opts2.VariableNames = ["Test_ID", "Name", "Pc_psi", "kfw_mdft"];
opts2.VariableTypes = ["double", "categorical", "double", "double"];

% Specify variable properties
opts2 = setvaropts(opts2, "Name", "EmptyFieldRule", "auto");

% Import the data
exp_data = readtable("C:\Users\tohoko.tj\dissolCases\/exp_data.xlsx", opts2, "UseExcel", false);

% Clear temporary variables
clear opts2


% Set up the Import Options and import the data
opts3 = spreadsheetImportOptions("NumVariables", 25);

% Specify sheet and range
opts3.Sheet = "ExpHeader";
opts3.DataRange = "A2:Y90";

% Specify column names and types
opts3.VariableNames = ["Test_ID", "Name", "Student", "RockType", "Location", "Surface", "AcidType", "FluidSystem", "Leakoff", "left_top_", "right_left_", "Value_etched_vol", "Value_lambda_x__in", "Value_lambda_z__in", "Value_stdev", "AvgLORate_ml_min_", "Temperature_F_", "PumpTime_min_", "ConductivityTestDate", "AdditionalNotes", "x0ClosureStressVolume", "ProfilometerFileName", "Ref", "Porosity", "Permeability"];
opts3.VariableTypes = ["double", "string", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "double", "double", "double", "string", "string", "string", "double", "double", "double", "double", "string", "double", "string", "categorical", "double", "double"];

% Specify variable properties
opts3 = setvaropts(opts3, ["Name", "Value_lambda_x__in", "Value_lambda_z__in", "Value_stdev", "AdditionalNotes", "ProfilometerFileName"], "WhitespaceRule", "preserve");
opts3 = setvaropts(opts3, ["Name", "Student", "RockType", "Location", "Surface", "AcidType", "FluidSystem", "Leakoff", "Value_lambda_x__in", "Value_lambda_z__in", "Value_stdev", "AdditionalNotes", "ProfilometerFileName", "Ref"], "EmptyFieldRule", "auto");

% Import the data
exp_data2 = readtable("C:\Users\tohoko.tj\dissolCases\exp_data.xlsx", opts3, "UseExcel", false);

% Clear temporary variables
clear opts3


% Join tables
joinedData = outerjoin(exp_data,exp_data2,"Keys","Test_ID","MergeKeys",true);

% Create scatter of joinedData.Pc_psi and joinedData.kfw_mdft
s3 = scatter(joinedData.Pc_psi,joinedData.kfw_mdft,joinedData.Test_ID,joinedData.Value_etched_vol,"DisplayName","kfw_mdft");

% Add xlabel, ylabel, title, and legend
xlabel("Pc_psi")
ylabel("kfw_mdft")
title("kfw_mdft vs. Pc_psi")
legend
set(gca, 'YScale', 'log', 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
grid on