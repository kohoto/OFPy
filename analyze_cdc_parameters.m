% Analysis on conductivity decline curve
clear; close all;
cc = tamu_color();
lbl = my_labels();
lims = my_lims();
varxname = 'P';
varyname = 'pe_slope';
plotbypc = 1;
colorby_name = 'stdev';
sizeby_name = 'lamx';
pc = [0:1000:4000];

err_flag = 0;
s = jsondecode(fileread('cdc.json'));
ndata = size(fieldnames(s), 1);
casenames = fieldnames(s);
ncol = 2;
x = nan(ndata, 1);
y = nan(ndata, ncol);

[p_cdc_slope, p_cdc_interp] = deal(nan(ndata, 1));
[p_cdc_each_slope, p_cdc_each_interp, stdev_for_each, lamx_for_each] = deal([]);
for j = 1:ndata
    casename = casenames(j);
    currentcase = s.(casename{:});
    if isfield(currentcase, varxname); x(j) = currentcase.(varxname); end
    if isfield(currentcase, 'p_cdc') 
        p_cdc_slope(j) = currentcase.p_cdc(1);
        p_cdc_interp(j) = currentcase.p_cdc(2);
    end
    if isfield(currentcase, 'p_cdc_each') 
        p_cdc_each_slope = [p_cdc_each_slope; currentcase.p_cdc_each(:,1)];
        p_cdc_each_interp = [p_cdc_each_interp; currentcase.p_cdc_each(:,2)];
        stdev_for_each = [stdev_for_each; currentcase.stdev * ones(size(currentcase.p_cdc_each(:,1)))];
        lamx_for_each = [lamx_for_each; currentcase.lamx * ones(size(currentcase.p_cdc_each(:,1)))];
    end
    % if isfield(currentcase, 'p2_slope'); p_cdc_slope(j) = currentcase.p2_slope; end
    % if isfield(currentcase, 'p2_intercept'); p_cdc_interp(j) = currentcase.p2_intercept; end

end

%% Figure 2: slope of wavg vs cond at different Pcs.
p_cdc(:, :, 1) = reshape(p_cdc_slope, [4, 4]);
p_cdc(:, :, 2) = reshape(p_cdc_interp, [4, 4]);

analyze_slope_and_interp_vs_sdv_and_lamx(p_cdc)



% show indivisual points as well
sdv = [0.025, 0.05, 0.075, 0.1]';
sdvs = repmat(sdv, [1, 4]);
lamx = [1, 2, 4, 6];
lamxs = repmat(lamx, [4, 1]);
axs = create_tiledlayout(1, 2, 0.5);
yname = {'C2 [1/psi]', 'C1 [md-ft]'};
for i = 1:2
    % Perform surface fitting
    disp('==============================================')
    % analyze this all points
    [pp, gof] = fit([stdev_for_each(:), lamx_for_each(:)], p_cdc_each_slope(:), 'poly22')

    Z_fit = feval(pp, [sdvs(:), lamxs(:)]);
    Z_fit = reshape(Z_fit, size(sdvs));
    surf(axs(3-i), sdvs, lamxs, Z_fit, 'FaceColor', cc(3, :), 'FaceAlpha', 0.5, 'EdgeColor',  cc(3, :)); % Plot fitted surface
    hold(axs(3-i), 'on')
    scatter3(axs(3-i), stdev_for_each, lamx_for_each, p_cdc_each_slope, [], cc(1, :), 'filled'); % Plot data points
    xlabel(axs(3-i), lbl.sdv, 'Interpreter', 'latex');
    ylabel(axs(3-i), lbl.lamx, 'Interpreter', 'latex');
    zlabel(axs(3-i), yname{i}, 'Interpreter', 'latex');
    legend(axs(3-i), 'Fit', 'Data');

    % Get the coefficients of the fitted equation
    %coeffs = coeffvalues(pp);    
    % Create a string to display the coefficients and R-squared value
    str = sprintf('R-squared: %f', gof.rsquare);
    % Display the string on the plot
    text(axs(3-i), max(sdvs(:)), max(lamxs(:)), max(p_cdc_each_slope(:)), str, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    axs(3-i) = my_plot_format(axs(3-i));
end




