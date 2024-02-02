% Read and plot CD2 result from Deng's excel file.
clear; close all;
nx = 35;
ny = 141;
max_w = 0.04;
range = 1:113; % plotting range
data = readmatrix('CD2_width.xlsx','Sheet','Sheet3');
x = data(:,1);
x = reshape(x,[nx,ny]);
x = repmat(x(1,:),nx,1);
y = data(:,2);
y = reshape(y,[nx,ny]);
w_b = data(:,3);
w_b = reshape(w_b,[nx,ny]);
for iter =1:3
w_b_mins = min(w_b,[],1);
w_b = w_b - repmat(w_b_mins,nx,1);
end

figure(1)
s = pcolor(x(:,range), y(:,range), w_b(:,range));
s.FaceColor = 'interp';
set(s, 'edgecolor','none')
colorbar;
caxis([0 max_w]);
figure(2)
w_a = data(:,6)*0.0393701; % mm to inch
w_a = reshape(w_a,[nx,ny]);
s = pcolor(x(:,range), y(:,range), w_a(:,range));
s.FaceColor = 'interp';
set(s, 'edgecolor','none')
colorbar;

%figure(3) % This is the input shown in the dissertation!!
niter = 5;
for iter=1:niter
figure(2+iter)
    %subplot(niter,1,iter);
w_a = data(:,12+iter);
if (iter~=1)
    w_a = w_a*0.0393701; % mm to inch
end
w_a = reshape(w_a,[nx,ny]);
s = pcolor(x(:,range), y(:,range), w_a(:,range));
s.FaceColor = 'interp';
set(s, 'edgecolor','none')
colorbar;
xlabel('X [inch]'); ylabel('Y [inch]');
if (iter==2)
    title(['Closure stress = ',num2str((iter-1)*1000),' psi']);
    caxis([0 0.022]);
elseif (iter~=1)
    title(['Closure stress = ',num2str((iter-1)*1000),' psi']);
    caxis([0 0.017]);
else
    title('Initial width distribution');
    
    % Compute average width
    %w_a_mins = min(w_a,[],1);
    %w_a = w_a - repmat(w_a_mins,nx,1);
    w0avg = mean(w_a(:,range),'all');
end
end

%% Average width plot
nPc = 4;
figure(5)
plot([0:nPc]*1000,[w0avg 0.0075 0.0049 0.0031 0.0011],'-o','DisplayName','Tohoko'); hold on;
% plot Deng's result
plot([0:nPc]*1000,[0.023 0.009 0.0075 0.006 0.0049],'-o','DisplayName','Deng'); hold on;
xlabel('Closure pressure [psi]');
ylabel('Average width in inch');
legend show;

%% Conductivity plot
figure(4)

% Mine
semilogy([1:nPc]*1000,[1918,521,135,6],'-o','DisplayName','Tohoko'); hold on;
%semilogy([0:nPc]*1000,cond_cub,'-o','DisplayName','from cubic law'); hold on;
%semilogy([0:nPc]*1000,cond_num,'-o','DisplayName','from simulation'); hold on;
% Deng
semilogy([1:nPc]*1000,[2614 1698 189 10],'-o','DisplayName','Deng'); hold on;
% Experiment
semilogy([1:nPc]*1000,[2210 1779 206 206],'-o','DisplayName','Experiment'); hold on;
xlabel('Closure pressure [psi]');
ylabel('Conductivity [md-ft]');
legend show;
hold off;