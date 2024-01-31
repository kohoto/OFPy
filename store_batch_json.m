function [dataStruct, err_flag] = store_batch_json(dataStruct, file_name, cases_meet_condition)

% Loop over each subfolder
err_flag = 0;
%if isfolder(fullfile(cases_meet_condition, 'etching', '600'))
jsonFile = fullfile(cases_meet_condition, file_name);
if isfile(jsonFile)
    % Read the JSON file
    % Save the data in the struct
    % Create a string
    % Split the string by the backslash
    splitted_str = split(cases_meet_condition, '\');
    batch_name = char(splitted_str(end-1));
    case_name = splitted_str(end);
    s = jsondecode(fileread(jsonFile));
    if file_name == "cond.json" && ~isfield(s, 'cond')  % simulation data
        if ~isfield(s, 'wid_e__in') || (isnan(s.wid_e__in) || isinf(s.wid_e__in))
            err_flag = 3;
        else
            for i = [0, 1000, 2000, 3000, 4000]

                if isfield(s, ['pc_', num2str(i)])
                    if i > 0 && s.(['pc_', num2str(i)]).cond__mdft >= s.(['pc_', num2str(i-1000)]).cond__mdft
                        err_flag = 6; % conductivity must be decreasing as pc increases.
                        break
                    elseif s.(['pc_', num2str(i)]).cond__mdft < 1
                        err_flag = 7; % don't include them because it's too low.
                        break
                    elseif isnan(s.(['pc_', num2str(i)]).cond__mdft) || isinf(s.(['pc_', num2str(i)]).cond__mdft) || s.(['pc_', num2str(i)]).cond__mdft < 0
                        err_flag = 3; % cond is inf or nan
                        break
                    elseif isnan(s.(['pc_', num2str(i)]).avg_w__in) || isinf(s.(['pc_', num2str(i)]).avg_w__in)
                        err_flag = 3; % cond is inf or nan
                        break
                    end
                else
                    err_flag = 2; % no pc_field recorded. run cond calculation again.
                    break
                end
            end
        end
        if err_flag == 0
            % add to struct only when the data looks good.
            dataStruct.(strrep(strjoin([batch_name(1:8), case_name(7:end)], ''), '-', '_')) = s;
        end

    elseif file_name == "cond.json" && isfield(s, 'cond')
        dataStruct.(strrep(case_name{:}, '-', '_')) = s;
    else % other type of data?
        dataStruct.(strrep(case_name{:}, '-', '_')) = s;
    end
else
    err_flag = 1; % 1: cond.json doesn't exist.
end
