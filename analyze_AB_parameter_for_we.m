
% Analysis on Mateus's proposed model coefficients A and B
% Expect both A and B are similar for the same 
clear; close all;
cc = tamu_color();

polyfit_name = 'p_AB';
% polyfit_name = 'p_alphabeta';
%polyfit_name = 'p_pq';
pc = [0:1000:4000];
sdv0 = 0.1;
lx = 7;

s = jsondecode(fileread('ana.json'));
ndata = size(fieldnames(s), 1);
casenames = fieldnames(s);


for j = 1:ndata
    casename = casenames(j);
    currentcase = s.(casename{:});
    if isfield(currentcase, polyfit_name)
        if j == 1
            npc = size(currentcase.(polyfit_name), 2);
            [p_slope, p_interp] = deal(nan(ndata, npc));
        end
        p_interp(j,:) = currentcase.(polyfit_name)(1, :); % A
        p_slope(j,:) = currentcase.(polyfit_name)(2, :); % B
    end
end

%% Figure 2: slope of wavg vs cond at different Pcs.
for ipc = 1:npc
    p(:, :, ipc, 1) = reshape(p_interp(:,ipc), [4, 4]);
    p(:, :, ipc, 2) = reshape(p_slope(:,ipc), [4, 4]);
end

if polyfit_name == "p_AB"
    analyze_slope_and_interp_vs_sdv_and_lamx(p(:,:,2:5,:), 'AB')
    %% take the average of the slope at each lambda and sdv, then fit surface.
    p = mean(p, 3);
    analyze_slope_and_interp_vs_sdv_and_lamx(p, 'AB')
elseif polyfit_name == "p_alphabeta"
    analyze_slope_and_interp_vs_sdv_and_lamx(p, 'alphabeta')
elseif polyfit_name == "p_pq"
    analyze_slope_and_interp_vs_sdv_and_lamx(p, 'pq')
end

all_figures_visiblity_on()

