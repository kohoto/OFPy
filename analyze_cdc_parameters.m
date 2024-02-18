% Analysis on conductivity decline curve
clear; close all;
cc = tamu_color();

pc = [0:1000:4000];
sdv0 = 0.1;
lx = 7;

s = jsondecode(fileread('cdc.json'));
ndata = size(fieldnames(s), 1);
casenames = fieldnames(s);

[p_cdc_slope, p_cdc_interp] = deal(nan(ndata, 1));
for j = 1:ndata
    casename = casenames(j);
    currentcase = s.(casename{:});
    if isfield(currentcase, 'p_cdc') 
        p_cdc_interp(j) = currentcase.p_cdc(1);
        p_cdc_slope(j) = currentcase.p_cdc(2);
    end
end

%% Figure 2: slope of wavg vs cond at different Pcs.
p_cdc(:, :, 1) = reshape(p_cdc_interp, [4, 4]);
p_cdc(:, :, 2) = reshape(-p_cdc_slope, [4, 4]);

analyze_slope_and_interp_vs_sdv_and_lamx(p_cdc, 'C1C2')
all_figures_visiblity_on()

