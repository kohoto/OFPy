function d = store_exp_var_from_excel()

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
exp_data2 = readtable("C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\30_Codes\Python\OFPy\/exp_data.xlsx", opts2, "UseExcel", false);

% Clear temporary variables
clear opts2


% Set up the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 26);

% Specify sheet and range
opts.Sheet = "ExpHeader";
opts.DataRange = "A2:Z90";

% Specify column names and types
opts.VariableNames = ["Test_ID", "Name", "Student", "RockType", "Location", "Surface", "AcidType", "FluidSystem", "Leakoff", "left_top_", "right_left_", "Value_etched_vol", "Value_lambda_x__in", "Value_lambda_z__in", "Value_stdev", "AvgLORate_ml_min_", "Temperature_F_", "PumpTime_min_", "ConductivityTestDate", "AdditionalNotes", "x0ClosureStressVolume", "ProfilometerFileName", "Ref", "Porosity", "Permeability", "Exp_type"];
opts.VariableTypes = ["double", "string", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "double", "string", "categorical", "double", "double", "categorical"];

% Specify variable properties
opts = setvaropts(opts, ["Name", "Value_lambda_x__in", "Value_lambda_z__in", "Value_stdev", "AdditionalNotes", "ProfilometerFileName"]);
opts = setvaropts(opts, ["Name", "Student", "RockType", "Location", "Surface", "AcidType", "FluidSystem", "Leakoff", "Value_lambda_x__in", "Value_lambda_z__in", "Value_stdev", "AdditionalNotes", "ProfilometerFileName", "Ref", "Exp_type"], "EmptyFieldRule", "auto");

% Import the data
exp_data = readtable("C:\Users\tohoko.tj\OneDrive - Texas A&M University\Documents\30_Codes\Python\OFPy\exp_data.xlsx", opts, "UseExcel", false);

% Clear temporary variables
clear opts


% Join tables
d = outerjoin(exp_data,exp_data2,"Keys","Test_ID");
end