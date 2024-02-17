function Deng_closure_gpt(casepath)
% input surface2_30.dat
% output width(after).dat

%% unit converters
psi2pa = 6894.75728;
ft2m = 0.304722;
mm2in = 0.0393701;
m2mm = 1000;

nx = 64;                 % Points number along length direction
ny = 256;                % Points number along height direction
Lx = 10 * ft2m;       % Fracture length in meter
Ly = 10 * ft2m;       % Fracture height in meter
pv = 6000 * psi2pa;       % Vertical stress in Pa
% ph = 3000 * 6894.75728;       % Horizontal stress in Pa, don't need this
% anymore since looping with different closure stress
ym = 4000000 * psi2pa;    % Young's modulus in Pa
pr = 0.3;                     % Poisson ratio
% pi = 3.141592654;             % PI

dx = Lx / (nx - 1);
dy = Ly / (ny - 1);
sm = ym / 2 / (1 + pr);
pcs = [0:1000:4000] .* psi2pa;
w_i = zeros(nx, ny);


fp1 = fopen(fullfile(casepath, 'etching', 'suface1_30.dat'), 'r');  % Input file
temp = textscan(fp1, '%f %f %f %*[^\n]', 'HeaderLines', 8); % [ft, mm ,ft]'
temp = temp(:, 2);
temp = temp{:};

k=0;
for i = 1:ny
    for j = 1:nx
        k=k+1;
        w_i(j, i) = temp(k) * (-2);  % Width in millimeter
        if w_i(j, i) <= 0
            w_i(j, i) = 0;
        end
    end
end

w_avg_Mou = (w_i - repmat(min(w_i(:, 2:end-1), [], 2), [1, ny])); % mm;
w_avg_Mou(:, [1, end]) = 0;
fclose(fp1);

w_avg_Mou_wo_bc = w_avg_Mou(:, 2:end-1);
data = struct(...
    'wid_e__in', sum(w_i(:)) / numel(w_i) * mm2in,... 
    'w0_Mou', sum(w_avg_Mou_wo_bc(:)) / numel(w_i(:, 2:end-1)) * mm2in...
    );

% Write the JSON data to a file
fid = fopen(fullfile(casepath, 'cond.json'), 'w');
if fid == -1
    error('Could not open file for writing');
end
fwrite(fid, jsonencode(data), 'char');
fclose(fid);

% I started to think he was using Mou's 0 closure stress width for the at beginning
w_i = w_avg_Mou;

for ph = pcs
    [wkf_nk, wkf_md] = getConductivity(data.wid_e__in, 1, 0.006, ym / psi2pa / 1e6, ph / psi2pa, 0.1, 0.5, 0.25);
    disp(['NK_we: ', num2str(wkf_nk), ', MD_we: ', num2str(wkf_md)])
    % [wkf_nk, wkf_md] = getConductivity(data.w0_Mou, 1, 0.006, ym / psi2pa / 1e6, ph / psi2pa, 0.1, 0.5, 0.25);
    % disp(['NK_wavg: ', num2str(wkf_nk), ', MD_wavg: ', num2str(wkf_md)])
end


for ph = pcs
w_c = zeros(1, ny);
w_o = zeros(nx, ny);
a = zeros(1, ny);
% main closure code
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
            b_s = b_sum / l / 2 / m2mm;  % In meter
            c_s = sqrt(a_s^2 - b_s^2);   % Focus in meter
            sinh_s = b_s / c_s;
            cosh_s = a_s / c_s;
            disp_s = m2mm * 2 * c_s * (1 - pr^2) / ym * (2 * ph * cosh_s + ph * sinh_s - pv * sinh_s);
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
            r_c = 1 - 2 * a_sum / Ly;
            disp_m = m2mm * 4 * ph * (pr - 1) * a_m * log(abs(cos(pi * (1 - r_c) / 2))) / (1 - r_c)^2 / pi / sm;
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

% temporary adding grids on both x and y to fit with my mesh
w_o = [w_o(1, :); w_o];
w_o = [w_o(:, 1), w_o];
w_avg_Mou = [w_avg_Mou(1, :); w_avg_Mou];
w_avg_Mou = [w_avg_Mou(:, 1), w_avg_Mou];

xvec = repmat([0:dx:(nx-1)*dx]' ./ ft2m, [1, ny]); % ft
yvec = repmat([0:dy:(ny-1)*dy] ./ ft2m, [nx, 1]); % ft
wvec = w_o(:); % mm - caluclated using Deng's closure model
wivec = w_avg_Mou(:);

[A, B, C] = NK_correlation_params(ym ./ psi2pa);
kfw_NK_mdft = get_conductivity(wivec .* mm2in, ph / psi2pa, A, B, C);
kfw_NK = kfw_NK_mdft ./ 1.0133e15 .* ft2m; % [m3]

% min-width thres in my model?? 
wid_thres_exp = 3.28914e-3; % [mm]
disp(['# of points that is less than the experimental scale width threshold = ', num2str(sum(wvec < wid_thres_exp)),...
    ' (', num2str(sum(wvec < wid_thres_exp) / numel(w_avg_Mou) * 100), ' %)']);
disp(['# of points with 0 width = ', num2str(sum(wvec == 0)),...
    ' (', num2str(sum(wvec == 0) / numel(w_avg_Mou) * 100), ' %)']);
wvec(wvec  < wid_thres_exp) = (12 .* kfw_NK(wvec  < wid_thres_exp)) .^ (1 / 3) .* m2mm; % [mm] % for the location that is w_o = 0, use NK corr.
wvec(wvec == 0) = wid_thres_exp; % for the location wvec = 0 even after assigning NK corr. width, use the threshold_width from the experimental scale.
disp(['# of points with 0 width even after applying exp scale corr. = ', num2str(sum(wvec == wid_thres_exp)),...
    ' (', num2str(sum(wvec == wid_thres_exp) / numel(w_avg_Mou) * 100), ' %)']);
disp('==============')
% w_result = reshape(w_after,[nx*nz,1]);
roughness_header = {"Closed Frac Width dist."; ...
" 1  257   65    1 0.12500000E-01 0.12500000E-01     0.00000000 0.250000E-01 0.250000E-01  1.00000       1";... % not accurate
"value"};
writecell([roughness_header; num2cell(wvec(:) ./ 2 .* mm2in)], fullfile(casepath, ['roughness', num2str(ph / psi2pa), '.dat']));

% % roughness_header = { ...
% %     "TITLE = 'AftrerClosureWidth'"; ... 
% %     "VARIABLES = 'x (feet)'"; ...
% %     "'z (feet)'"; ...
% %     "'y (mm)'"; ...
% %     "'k (md)'"; ...
% %     "'Ef ()'"; ...
% %     "ZONE T = 'Data'"; ...
% %     "I = 64, J = 256 ZONETYPE = Ordered"; ... 
% %     "DATAPACKING = POINT"; ...
% %     "DT = (SINGLE SINGLE SINGLE  SINGLE SINGLE)" };
% % % Convert numbers to formatted strings
% % c = num2cell([xvec(:), yvec(:), -wvec(:), zeros(size(wvec, 1), 2)]);
% % c = cellfun(@(x) sprintf('%.8f', x), c, 'UniformOutput', false);
% % writecell([roughness_header, cell(size(roughness_header, 1), 4); c], 'roughness.dat','Delimiter',' ', 'QuoteStrings', 'none');
% writetable(T,'myData.txt','Delimiter',' ') 

end
end

%% external functions
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
