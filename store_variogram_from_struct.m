function [plot_struct_x, plot_struct_y, marker_sizes, colors, disp_names] = store_variogram_from_struct(dataStruct, var_name)
% Loop over each field
cc = tamu_color();
fields = fieldnames(dataStruct);
n_plot = numel(fields);
disp_names = string(fields);
timing = ["before", "after"];
side = ["top", "btm"];
direction = ["varx", "vary"];

% check data length of the variogram plot
n_data = numel(dataStruct.(fields{1}).(timing(1)).(side(1)).(direction(1)).('lag'));

marker_sizes= 10 * ones(n_plot, 1);
[data_x, data_y] = deal(nan(n_plot, n_data));
colors = cc(mod([1:size(cond, 1)], size(cc, 1)) + 1, :);

plot_struct_x = struct();
plot_struct_y = struct();
for j = 1:2
    for k = 1:2
        for l = 1:2
            for i = 1:numel(fields)
                % get conductivity values
                data_x(i, :) = dataStruct.(fields{i}).(timing(j)).(side(k)).(direction(l)).('lag');
                data_y(i, :) = dataStruct.(fields{i}).(timing(j)).(side(k)).(direction(l)).('gamma');
            end
            plot_struct_x.(timing(j)).(side(k)).(direction(l)) = data_x;
            plot_struct_y.(timing(j)).(side(k)).(direction(l)) = data_y;
        end
    end
end
