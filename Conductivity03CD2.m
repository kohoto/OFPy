clear; close all;
%Transplant Deng's Excel VBA code to Matlab
% Input values
nx = 113;
ny = 35;
v = xlsread('Conductivity03CD2.xls','Knowns','B3');
e = xlsread('Conductivity03CD2.xls','Knowns','E2');
pv = xlsread('Conductivity03CD2.xls','Knowns','E6');
ph = xlsread('Conductivity03CD2.xls','Knowns','E7');
Ly = xlsread('Conductivity03CD2.xls','Knowns','B11');
dy = xlsread('Conductivity03CD2.xls','Knowns','B16');
g = e / 2 / (1 + v);
idx_temp = 0;

PH = 1000:1000:4000;
nPc = size(PH,2);
w_mean = zeros(nPc,1);
w_max = zeros(nPc,1);

%% Read data from Excel 'dataset' tab
range = ['A3:C',num2str(nx*ny+2)];
data1 = readmatrix('Conductivity03CD2.xls','Sheet','Dataset','Range',range);
x = reshape(data1(:,1),ny,nx)' .*0.0254; % in -> m
y = reshape(data1(:,2),ny,nx)' .*0.0254; % in -> m

for iPc=1:nPc
    
    ph = PH(iPc) * 6894.75728;
    w = reshape(data1(:,3),ny,nx)' .*25.4; % in -> mm
    w_after = zeros(size(w));
    cond =  zeros(nx,1);
    m_result =  zeros(nx,1);
    %% Loop in x-dir
    for ix=1:nx
        %% Copy the data of this cross-section
        y_cs = y(ix,:);
        w_cs = w(ix,:);
        
        %% Compute zero closure stress width
        w_min = w_cs(1);
        % This is not to choose the outside grid as the minimum.
        % Modified on 12/1/2020
        for iy = 2:ny-1
            if w_min > min(w_cs(iy:end-1)) % Why exclude the last one?
                w_min = min(w_cs(iy:end-1));
                break;
            else
                w_min = w_cs(iy);
            end
        end
        w_cs = w_cs - w_min;
        w_cs(w_cs<0) = 0;
        
        %% Eliminate the effect of upper boundary
        for iter=1:100 % While either of them is non zero
            % BREAK CODITIONS
            if ((iter == 1) && (w_cs(1)==0 || w_cs(2)==0))
                w_cs(1) = 0;
                % This is just to follow Deng's code. But it's mistake
                rowb = find(w_cs(3:end)==0,1)+2;
                idx_temp = rowb - 1;
                w_temp = w_cs(rowb-1);
                w_cs(rowb-1) = 0;
                break;
            elseif(w_cs(2)==0)
                w_cs(1) = 0;
                break;
            elseif(w_cs(1)==0)
                break;
            end
            % iteration
            rowb = find(w_cs==0,1);
            w_min = min(w_cs(1:rowb-1));
            if (w_min == w_cs(rowb-1) && (w_cs(rowb-1)>w_cs(rowb-2) || w_cs(rowb-1)>w_cs(1)))
                w_cs(1:rowb-1) = w_cs(1:rowb-1) - w_cs(1);
            else
                w_cs(1:rowb-1) = w_cs(1:rowb-1) - w_min;
            end
        end
        
        %% Eliminate the effect of bottom boundary
        for iter=1:100
            % exit loop conditions
            if(iter==1 && (w_cs(end-1)==0 || w_cs(end)==0))
                if(w_cs(end-1)==0)
                    w_cs(end)=0;
                end
                % This is just to follow Deng's code. But it's mistake
                rowu = find(w_cs(1:end-2)==0,1,'last');
                if (rowu==idx_temp)
                    w_cs(idx_temp) = w_temp;
                end
                break;
            elseif (w_cs(end-1)==0)
                w_cs(end) = 0;
                break;
            elseif (w_cs(end)==0)
                break;
            end
            % iterations
            rowu = find(w_cs==0,1,'last');
            w_min = min(w_cs(rowu+1:end-1));
            if (w_min == w_cs(end)) && (w_cs(end) > w_cs(end-1))
                w_cs(rowu:end) = 0;
            elseif (w_min > w_cs(end))
                w_cs(rowu+1:end) = w_cs(rowu+1:end) - w_cs(end);
            else
                w_cs(rowu+1:end) = w_cs(rowu+1:end) - w_min;
            end
        end
        
        %% Compute closure width. Keep closing until all ellipse has ellipse shape.
        flag = 0;
        iter2 = 0;
        while sum(w_cs~=0)>=1
            iter2 = iter2 +1;
            % Find width loop
            m = 0;
            hrow = 1;
            suma = 0;
            while (hrow < ny-1)
                lrow = find(w_cs(hrow+1:end)==0,1) + hrow;
                if (lrow > hrow+1)
                    m = m+1;
                    suma = suma + 0.5 * (y_cs(lrow)-y_cs(hrow));
                    hrow4m1 = hrow;
                end
                hrow = lrow;
            end
            
            % If there is only one ellipse,
            if m==1
                % This is just to eliminate 0s when search min
                w_cs1 = w_cs;
                w_cs1(w_cs<=0) = 100;
                [w_min, r] = min(w_cs1);
                if r == hrow4m1+1 || r == lrow-1
                    a2 = suma;
                    hrow = 1;
                    while hrow<ny
                        lrow = find(w_cs(hrow+1:end)==0,1)+hrow;
                        if lrow == hrow+1
                            hrow = lrow;
                        else
                            sumw = sum(w_cs(hrow:lrow));
                            b2 = 0.5 * sumw / (lrow - hrow - 1) / 1e3;
                            c2 = sqrt(a2*a2 - b2*b2);
                            sinh2 = b2/c2;
                            cosh2 = a2/c2;
                            disp2 = 2*c2*(1-v*v)/e*(2*ph*cosh2+ph*sinh2-pv*sinh2);
                            
                            if (disp2 >= w_min * 1e-3)
                                w_cs = w_cs - w_min;
                                w_cs(w_cs<0) = 0;
                            else
                                w_after(ix,:) = w_cs - disp2*1000;
                                w_after(ix,w_after(ix,:)<0) = 0;
                                flag = 1;
                                break
                            end
                            hrow = lrow; % Can delete this
                        end
                    end
                    if flag == 1
                        break
                    end
                else %If the minimum width can be found in the middle of the fracture => ellipse will be two at the end
                    
                    a1 = suma;
                    xx = abs(a1 - (y_cs(r) - y_cs(hrow4m1)));
                    yy = 0.5 * w_min;
                    b1 = (yy / sqrt(1-xx*xx/a1/a1)) *1e-3;
                    c1 = sqrt(a1*a1 - b1*b1);
                    % Displacement calculation
                    sinh1 = b1/c1;
                    cosh1 = a1/c1;
                    disp1 = 2*c1*(1-v*v)/e*(2*ph*cosh1+ph*sinh1-pv*sinh1);
                    if disp1 >=w_min * 1e-3
                        w_cs = w_cs - w_min;
                        w_cs(w_cs<0) = 0;
                        
                    else
                        w_after(ix,:) = w_cs - disp1*1000;
                        w_after(ix,w_after(ix,:)<0) = 0;
                        break;
                    end
                end
            else % If there are multiple ellipses (m>1)
                avga = suma / m;
                ctratio = 1 - suma / Ly; % Different from the original!!
                disp1 = 1000 * 2 * ph * (v - 1) * avga * log(abs(cos(pi * (1 - ctratio)))) / (1 - ctratio) / pi / g;
                w_min = min(w_cs(w_cs>0));
                
                if disp1 >=w_min
                    w_cs = w_cs - w_min;
                    w_cs(w_cs<0) = 0;
                else
                    w_after(ix,:) = w_cs - disp1;
                    w_after(ix,w_after(ix,:)<0) = 0;
                    break;
                end
            end %Fracture closure process
        end
        
        
        %% Conductivity calculation
        hrow = 1;
        while(hrow < ny-1)
            % Add all width in this ellipse
            lrow = find(w_after(ix,hrow+1:end)==0,1)+hrow;
            if lrow == hrow+1
                hrow = lrow;
            else
                dy_cd = (lrow-hrow) * dy;
                w_avg = sum(w_after(ix,hrow+1:lrow-1)) / (lrow-hrow-1);
                w_avg_inch = w_avg * 0.03937;
                cond(ix) = cond(ix) + w_avg^3 * dy_cd;
                hrow = lrow;
            end
        end
        cond(ix) = cond(ix)/12/Ly/1000 / 9.9 / 3.048 * 1e8; % in md-ft
        m_result(ix) = m;
    end
    cond_avg(iPc) = nx/sum(1./cond);
    w_result = reshape(w_after',[nx*ny,1]);
    w_a{iPc} = w_after;
    w_mean(iPc) = 2*mean(w_result)*0.0393701;
    w_max(iPc) = 2*max(w_result)*0.0393701;
end

% Read and plot CD2 result from Deng's excel file.
max_w = 0.04;

% figure(1)
s = pcolor(x.*39.3701, y.*39.3701, reshape(data1(:,3),ny,nx)'); % m to inch
s.FaceColor = 'interp';
set(s, 'edgecolor','none')
colorbar;
caxis([0 max_w]);
title('Before closure width distribution');

for iPc=1:nPc
    figure
    w_a{iPc} = w_a{iPc}*0.0393701; % mm to inch
    s = pcolor(x.*39.3701, y.*39.3701, w_a{iPc});
    s.FaceColor = 'interp';
    set(s, 'edgecolor','none')
    colorbar;
    xlabel('X [inch]'); ylabel('Y [inch]');
    if (iPc==1)
        title(['Closure stress = ',num2str(iPc*1000),' psi']);
        caxis([0 0.022]);
    elseif (iPc~=1)
        title(['Closure stress = ',num2str(iPc*1000),' psi']);
        caxis([0 0.017]);
        
        % Compute average width
        %w_a_mins = min(w_a,[],1);
        %w_a = w_a - repmat(w_a_mins,nx,1);
        %w0avg = mean(w_a{iPc},'all');
    end
end

%% Average width plot
figure
plot([1:nPc]*1000,w_mean,'-o','DisplayName','Tohoko'); hold on;
% plot Deng's result
%plot([0:nPc]*1000,[0.023 0.009 0.0075 0.006 0.0049],'-o','DisplayName','Deng'); hold on;
w_avg_deng = [0.009 0.0075 0.006 0.0049];
plot([1:nPc]*1000,w_avg_deng,'-o','DisplayName','Deng'); hold on;
xlabel('Closure pressure [psi]');
ylabel('Average width in inch');
legend show;
% Relative error
err = (w_avg_deng' - w_mean)./w_avg_deng'.*100;
%% Max width plot
figure
plot([1:nPc]*1000,w_max,'-o','DisplayName','Tohoko'); hold on;
% plot Deng's result
plot([1:nPc]*1000,[0.0432 0.0408 0.0402 0.0397],'-o','DisplayName','Deng'); hold on;
xlabel('Closure pressure [psi]');
ylabel('Max width [inch]');
legend show;
%% Conductivity plot
figure
% Mine
%semilogy([1:nPc]*1000,cond_avg,'-o','DisplayName','Tohoko'); hold on;
%semilogy([0:nPc]*1000,cond_cub,'-o','DisplayName','from cubic law'); hold on;
semilogy([1:nPc]*1000,[1328 646 111 8],'-o','DisplayName','Tohoko, numerical'); hold on;
%semilogy([1:nPc]*1000,[2844 1573 775 415],'-o','DisplayName','Tohoko2'); hold on;%Tohoko from CLion Conductivity_avg
% Deng
semilogy([1:nPc]*1000,[2614 1698 189 10],'-o','DisplayName','Deng'); hold on;
% Experiment
semilogy([1:nPc]*1000,[2210 1779 206 206],'-o','DisplayName','Experiment'); hold on;
xlabel('Closure pressure [psi]');
ylabel('Conductivity [md-ft]');
legend show;
hold off;
