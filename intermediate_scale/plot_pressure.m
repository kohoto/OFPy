function plot_pressure()
clear; close all;
addpath('../')
case_dir = 'C:/Users/tohoko.tj/MouDeng/test01';
file_name = 'pressure.dat';

nx = 64;                 % Points number along length direction
ny = 256;                % Points number along height direction
Lx = 10 * 0.304722;       % Fracture length in meter
Ly = 10 * 0.304722;       % Fracture height in meter
pv = 6000 * 6894.75728;       % Vertical stress in Pa
ph = 3000 * 6894.75728;       % Horizontal stress in Pa
ym = 4000000 * 6894.75728;    % Young's modulus in Pa
pr = 0.3;                     % Poisson ratio
pi = 3.141592654;             % PI

dx = Lx / (nx - 1);
dy = Ly / (ny - 1);
sm = ym / 2 / (1 + pr);

prsrFile = fullfile(case_dir, file_name);
if isfile(prsrFile)
    prsrData = readmatrix(prsrFile);
    ax = create_tiledlayout(1, 1);
    contourf(ax, repmat([0:dx:(nx-1)*dx], ny, 1), ...
    repmat([0:dx:(ny-1)*dx]', 1, nx), ...
    reshape(prsrData(:,3), nx, ny)', 'EdgeColor', 'none');
end
