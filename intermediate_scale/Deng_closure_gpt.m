% input width.dat
% output width(after).dat
clear; close all;

lpoints = 64;                 % Points number along length direction
hpoints = 256;                % Points number along height direction
length = 10 * 0.304722;       % Fracture length in meter
height = 10 * 0.304722;       % Fracture height in meter
pv = 6000 * 6894.75728;       % Vertical stress in Pa
ph = 3000 * 6894.75728;       % Horizontal stress in Pa
ym = 4000000 * 6894.75728;    % Young's modulus in Pa
pr = 0.3;                     % Poisson ratio
pi = 3.141592654;             % PI

nx = lpoints;
ny = hpoints;
dx = length / (nx - 1);
dy = height / (ny - 1);
sm = ym / 2 / (1 + pr);

a = zeros(1, ny);
w_i = zeros(nx, ny);
w_c = zeros(1, ny);
w_o = zeros(nx, ny);

fp1 = fopen('width.dat', 'r');  % Input file

for i = 1:ny
    for j = 1:nx            
        temp = fscanf(fp1, '%lf %lf %lf', [1, 3]); % [m, m ,mm]
        w_i(j, i) = temp(3) * (-2);  % Width in millimeter
        if w_i(j, i) <= 0
            w_i(j, i) = 0;
        end
    end
end
w_avg_Mou = (w_i - repmat(min(w_i(:, 2:end-1), [], 2), [1, ny])); % mm;
w_avg_Mou(:, [1, end]) = 0;
fclose(fp1);

for i = 1:nx
    w_c = w_i(i, :);
    while true
        k = 0;
        m = 0;
        a_sum = 0;

        for j = 1:ny - 1
            if (w_c(j) == 0) && (w_c(j + 1) ~= 0)
                m = j;
            end
            if (w_c(j + 1) == 0) && (w_c(j) ~= 0)
                a(k + 1) = (j + 1 - m) * dy / 2;  % In meter
                a_sum = a_sum + a(k + 1);
                k = k + 1;
            end
        end

        if k == 1
            a_s = a_sum;
            b_sum = 0;
            l = 0;

            for j = 1:ny - 2
                if w_c(j + 1) ~= 0
                    b_sum = b_sum + w_c(j + 1);
                    l = l + 1;
                end
            end
            b_s = b_sum / l / 2 / 1000;  % In meter
            c_s = sqrt(a_s^2 - b_s^2);   % Focus in meter
            sinh_s = b_s / c_s;
            cosh_s = a_s / c_s;
            disp_s = 1000 * 2 * c_s * (1 - pr^2) / ym * (2 * ph * cosh_s + ph * sinh_s - pv * sinh_s);
            w_min = wmin(w_c);

            if disp_s > w_min
                w_c = w_c - w_min;
                w_c(w_c < 0) = 0;
            else
                w_c = w_c - disp_s;
                w_c(w_c < 0) = 0;
                break;
            end
        else
            a_m = a_sum / k;
            r_c = 1 - 2 * a_sum / height;
            disp_m = 1000 * 4 * ph * (pr - 1) * a_m * log(abs(cos(pi * (1 - r_c) / 2))) / (1 - r_c)^2 / pi / sm;
            w_min = wmin_m(w_c);

            if disp_m > w_min
                w_c = w_c - w_min;
                w_c(w_c < 0) = 0;
            else
                w_c = w_c - disp_m;
                w_c(w_c < 0) = 0;
                break;
            end
        end

        zero = 0;
        for j = 1:ny - 1
            if w_c(j) ~= 0
                zero = w_c(j);
            end
        end
        if zero == 0
            break;
        end
    end

    w_o(i, :) = w_c;
end

fp2 = fopen('width(after).dat', 'w+');  % Output

xvec = [];
yvec = [];
wvec = [];
wivec = [];
for i = 1:nx
    for j = 1:ny
        xvec = [xvec; (i - 1) * dx / 0.304722]; % ft
        yvec = [yvec; (j - 1) * dy / 0.304722]; % ft
        wvec = [wvec; w_o(i, j)]; % mm
        wivec = [wivec; w_avg_Mou(i, j)]; % mm
    end
end
fclose(fp2);
[A, B, C] = NK_correlation_params(ym ./ 6894.75728);
kfw_NK_mdft = get_conductivity(wivec .* 0.0393701, ph / 6894.75728, A, B, C);
kfw_NK = kfw_NK_mdft ./ (1.0133e15 * 3.28084); % [m3]
wvec(wvec == 0) = (12 .* kfw_NK(wvec == 0)) .^ (1 / 3) .* 1000; % [mm]
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
% w_result = reshape(w_after,[nx*nz,1]);
roughness_header = {"Closed Frac Width dist."; ...
" 1  256   64    1 0.12500000E-01 0.12500000E-01     0.00000000 0.250000E-01 0.250000E-01  1.00000       1";... % not accurate
"value"};
writecell([roughness_header; num2cell(wvec)], 'roughness.dat');

% min-width thres in my model?? 
wid_thres_exp = 3.28914e-3; % [mm]
disp(['# of points that is less than the experimental scale width threshold = ', num2str(sum(wvec < wid_thres_exp)),...
    ' (', num2str(sum(wvec < wid_thres_exp) / numel(w_avg_Mou) * 100), ' %)']);
% etched width = roughness
function kfw_mdft = get_conductivity(w_inch, ph_psi, A, B, C)
    kfw_mdft = A .* w_inch .^ B .* exp(C .* ph_psi); % subs inch
end

function [A, B, C] = NK_correlation_params(E)
Sres_psi = 0.0201 .* E - 25137;
    A = 1.476e7;
    B = 2.466;
    if 0 <= Sres_psi && Sres_psi< 2e4
        coeff = [13.9, 1.3];
    elseif Sres_psi >= 2e4
        coeff = [3.8, 0.28];
    else
        error('Sres_psi must be positive.')
    end
    C = -0.001 .* (coeff(1) - coeff(2) .* log(Sres_psi));
end



function xmin = wmin(a)
    hpoints = length(a);
    xmin = 1000;
    for i = 1:hpoints-2 % modifiied
        if (a(i+1) < xmin) && (a(i+1) < a(i)) && (a(i+1) < a(i+2)) && (a(i+1) ~= 0)
            xmin = a(i+1);
        end
    end
end

function xmin = wmin_m(a)
    hpoints = length(a);
    xmin = 1000;
    for i = 1:hpoints-1
        if (a(i+1) < xmin) && (a(i+1) ~= 0)
            xmin = a(i+1);
        end
    end
end
