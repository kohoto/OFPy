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
        temp = fscanf(fp1, '%lf %lf %lf', [1, 3]);
        w_i(j, i) = temp(3) * (-2);  % Width in millimeter
        if w_i(j, i) <= 0
            w_i(j, i) = 0;
        end
    end
end
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
for i = 1:nx
    for j = 1:ny
        xvec = [xvec; (i - 1) * dx / 0.304722];
        yvec = [yvec; (j - 1) * dy / 0.304722];
        wvec = [wvec; w_o(i, j)];
    end
end
fclose(fp2);


w_result = reshape(w_after,[nx*nz,1]);
writematrix([xvec, yvec, wvec], ['width(after)_3000.dat']);
disp('hi')

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
