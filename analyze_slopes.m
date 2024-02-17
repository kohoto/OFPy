%function analyze_slopes()
clear; close all;
cc = tamu_color();

varxname = 'lamx';
varyname = 'pe_slope';
plotbypc = 1;
colorby_name = 'stdev';
sizeby_name = 'lamx';
pc = [0:1000:4000];

err_flag = 0;
s = jsondecode(fileread('ana.json'));
ndata = size(fieldnames(s), 1);
casenames = fieldnames(s);
if startsWith(varyname, 'ps_') || startsWith(varyname, 'pe_')
    ncol = 5;
else
    ncol = 2;
end
x = nan(ndata, 1);
y = nan(ndata, ncol);
[wavg_slope, wavg_interp, we_slope, we_interp] = deal(nan(ndata, numel(pc)));
[p2_slope, p2_interp, p_cdc_slope, p_cdc_interp, colorby, sizeby, stdev, p_alpha, p_beta] = deal(nan(ndata, 1));
for j = 1:ndata
    casename = casenames(j);
    currentcase = s.(casename{:});
    if isfield(currentcase, varxname); x(j) = currentcase.(varxname); end
    if isfield(currentcase, colorby_name); colorby(j) = currentcase.(colorby_name); end
    if isfield(currentcase, 'stdev'); stdev(j) = currentcase.stdev; end
    if isfield(currentcase, sizeby_name); sizeby(j) = currentcase.(sizeby_name); end
    if isfield(currentcase, varyname); y(j, :) = currentcase.(varyname); end
    if isfield(currentcase, 'ps_slope'); wavg_slope(j, :) = currentcase.ps_slope; end %eta
    if isfield(currentcase, 'ps_interp'); wavg_interp(j, :) = currentcase.ps_interp; end%alpha
    if isfield(currentcase, 'pe_slope'); we_slope(j, :) = currentcase.pe_slope; end
    if isfield(currentcase, 'pe_interp'); we_interp(j, :) = currentcase.pe_interp; end
    if isfield(currentcase, 'p2_slope'); p2_slope(j) = currentcase.p2_slope; end
    if isfield(currentcase, 'p2_intercept'); p2_interp(j) = currentcase.p2_intercept; end
    if isfield(currentcase, 'p_beta'); p_beta(j) = currentcase.p_beta; end
    if isfield(currentcase, 'p_alpha'); p_alpha(j) = currentcase.p_alpha; end
end

ratio = log(wavg_slope) ./ log(we_slope);

%% Figure 2: slope of wavg vs cond at different Pcs.

sdv = unique(stdev); % co is color order
lamx = [1, 2, 4, 6];
nax = numel(sdv);
ax = create_tiledlayout(2, 2, 1);
for j = 1:numel(sdv)
    same_sdv = find(stdev == sdv(j));
    ax(j) = my_scatter(ax(j), 'plot', [colorby_name, ': ', num2str(sdv(j))],...
    repmat(sizeby(same_sdv)', [ncol, 1]), sizeby_name, 'normal', ...
    wavg_slope(same_sdv, :)', 'wavg vs cond slope', 'normal', ...
    7, cc(end-4:end, :), num2str([0:1000:4000]'));
    ax(j).XLim = [1, 6];
    ax(j).YLim = [0, 3.5];
    xlabel(ax(j), '\lambda_{x} [in]');
    ylabel(ax(j), 'Slope of w_{avg} vs conductivity loglog plot');
end


%% Figure 3: log(we) / log(wavg)
ax = create_tiledlayout(2, 3, 1);
for i = 1:ncol
    for j = 1:numel(sdv)
        same_sdv = find(colorby == sdv(j));
        ax(i) = my_scatter(ax(i), 'plot', [varxname, ' vs ', 'log(we) / log(wavg)'],...
        x(same_sdv)', varxname, 'normal', ...
        ratio(same_sdv, i)', 'ratio', 'normal', ...
        10, cc(j, :), num2str(sdv(j)));
    end
    ax(i).XLim = [1, 6];
    ax(i).YLim = [0.5, 2];
    % ax(i).YLim = [0.3, 3];
    set(ax(i), 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
    legend(ax(i), 'show')
end

%% Figure 4
ax = create_tiledlayout(1, 1, 1);
for j = 1:numel(sdv)
    same_sdv = find(colorby == sdv(j));
    ax = my_scatter(ax, 'plot', [varxname, ' vs ', 'p2 interp'],...
    x(same_sdv)', varxname, 'normal', ...
    p2_interp(same_sdv)', 'p2_interp', 'normal', ...
    10, cc(j, :), ['stdev = ', num2str(sdv(j))]);
end
ax.XLim = [1, 6];
% ax(i).YLim = [0.3, 3];
set(ax, 'MinorGridLineStyle', '-', 'XMinorGrid', 'off', 'YMinorGrid', 'off');
legend(ax, 'show')

%% Figure 5
ax = create_tiledlayout(1, 1, 1);
for j = 1:numel(sdv)
    same_sdv = find(colorby == sdv(j));
    ax = my_scatter(ax, 'plot', [varxname, ' vs ', '(we vs wavg (p2) slope)'],...
    x(same_sdv)', varxname, 'normal', ...
    p2_slope(same_sdv)', 'we vs wavg slope', 'normal', ...
    10, cc(j, :), num2str(sdv(j)));
end
ax.XLim = [1, 6];
legend(ax, 'show')


p(:, :, 1) = reshape(p2_slope, [4, 4]);
p(:, :, 2) = reshape(p2_interp, [4, 4]); % p and 1
analyze_slope_and_interp_vs_sdv_and_lamx(p) % we vs wa

p(:, :, 1) = reshape(p_beta, [4, 4]);
p(:, :, 2) = reshape(p_alpha, [4, 4]); % p and 1
analyze_slope_and_interp_vs_sdv_and_lamx(p) % we vs wa

p(:, :, 1) = reshape(we_slope(:, 2), [4, 4]);
p(:, :, 2) = reshape(we_interp(:, 2), [4, 4]); % p and 1
analyze_slope_and_interp_vs_sdv_and_lamx(p) % we vs cond