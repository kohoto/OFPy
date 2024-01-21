function dataStruct = store_batch_json(dataStruct, file_name, cases_meet_conditions)

% Loop over each subfolder
for k = 1 : length(cases_meet_conditions)
    % Get a list of all JSON files in this subfolder
    jsonFile = fullfile(cases_meet_conditions, file_name);      
    if isfile(jsonFile)
        % Read the JSON file
        jsonData = fileread(jsonFile);            
        % Save the data in the struct
        % Create a string
        % Split the string by the backslash
        splitted_str = split(cases_meet_conditions, '\');

        dataStruct.(strrep(strjoin(splitted_str(5:end), ''), '-', '_')) = jsondecode(jsonData);
    else
        disp([jsonFile, 'does not exist'])
    end
end