function [cond, pc, marker_sizes, colors, disp_names] = store_cond_var_from_struct(dataStruct, var_name, colored_by, sized_by)
% Loop over each field
cc = tamu_color();
pc = [0, 1000, 2000, 3000, 4000];
fields = fieldnames(dataStruct);
cond = zeros(numel(fields), numel(pc));
marker_sizes= nan(numel(fields), 1);
colors = nan(numel(fields), 3); %cc(mod([1:size(cond, 1)], size(cc, 1)) + 1, :);
disp_names = string(fields);

for i = 1:numel(fields)
    % get conductivity values
    case_data = dataStruct.(fields{i});
    for j = 1 : numel(pc)
        if isfield(case_data, ['pc_', num2str(pc(j))])
            cond(i, j) = case_data.(['pc_', num2str(pc(j))]).(var_name);
        else
            cond(i, j) = nan;
        end
    end

    % store color and size parameters
    colors(i, 1) = case_data.(colored_by);
    marker_sizes(i)  = case_data.(sized_by);

end

%% determine color and size of the markers
unique_colors = unique(colors(:,1));
max_color = max(unique_colors);
min_color = min(unique_colors);
max_size = max(marker_sizes);
min_size = min(marker_sizes);

if unique_colors <= size(cc, 1)
    for i = 1:numel(fields)
        [~, idx] = find(colors(i, 1) == unique_colors,1);
        colors(i, :) = cc(idx, :);
    end
else % if the value is more than the number of colors, or the value is continuous, use gray scale
    colors = repmat((colors(:, 1)-min_color) ./ (max_color - min_color), 1, 3);
end

% assume the marker size is always continuous paramter
marker_sizes = 2 + 10 .* (marker_sizes - min_size) ./ (max_size - min_size);

