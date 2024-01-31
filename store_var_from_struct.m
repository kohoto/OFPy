function [data, x, marker_sizes, colors, disp_names] = store_var_from_struct(dataStruct, var_name, var_name_x, colored_by, sized_by)
% Loop over each field
cc = tamu_color();
fields = fieldnames(dataStruct);
[data, x] = deal(nan(numel(fields), 1));
marker_sizes= nan(numel(fields), 1);
colors = nan(numel(fields), 3); %cc(mod([1:size(cond, 1)], size(cc, 1)) + 1, :);
disp_names = string(fields);

for i = 1:numel(fields)
    % get conductivity values
    case_data = dataStruct.(fields{i});
    if isfield(case_data, 'pc_0')
        x(i) = case_data.pc_0.(var_name_x);
        data(i) = case_data.(var_name);
    end


    % store color and size parameters
    if isnumeric(colored_by)
        colors(i, :) = colored_by;
    else
        if isfield(case_data, colored_by)
            colors(i, 1) = case_data.(colored_by);
        end
    end

    if isfield(case_data, sized_by)
        marker_sizes(i)  = case_data.(sized_by);
    end

end

%% determine color and size of the markers
if any(isnan(colors(:, 3)))  % if the colors are not determined,
    unique_colors = unique(colors(:,1));
    max_color = max(unique_colors);
    min_color = min(unique_colors);
    if unique_colors <= size(cc, 1)
        for i = 1:numel(fields)
            [~, idx] = find(colors(i, 1) == unique_colors,1);
            colors(i, :) = cc(idx, :);
        end
    else % if the value is more than the number of colors, or the value is continuous, use gray scale
        colors = repmat((colors(:, 1)-min_color) ./ (max_color - min_color), 1, 3);
    end
end

% assume the marker size is always continuous paramter
max_size = max(marker_sizes);
min_size = min(marker_sizes);
marker_sizes = 2 + 10 .* (marker_sizes - min_size) ./ (max_size - min_size);
% assign small value to the data points that doesn't have marker size
% paramters
marker_sizes(isnan(marker_sizes)) = 2;


% remove data points that has invalid numbers
valid_idx = all(~isnan([data, x]) & ~isinf([data, x]), 2);
data = data(valid_idx);
x = x(valid_idx);
marker_sizes = marker_sizes(valid_idx);
colors = colors(valid_idx, :);
disp_names = disp_names(valid_idx);
