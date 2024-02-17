function [wkf_nk, wkf_md] = getConductivity(wIdeal_inch, f_c, CL, E_mpsi, pc_psi, sigma, lambdax, lambdaz, test1)
if ~exist('test','var') test1=0; end
% for test
if test1
    wIdeal_inch(:) = 0.04;
end
SRES_psi = 0.0201 .* E_mpsi * 1e6 - 25137;
%% Nierode Kruk
if SRES_psi<2e4
    A = 1.476e7.*exp(-0.001.*(13.9-1.3.*log(SRES_psi)).*pc_psi); % md-ft-in^(-2.47)
else
    A = 1.476e7.*exp(-0.001.*(3.8-0.28.*log(SRES_psi)).*pc_psi);
end
B = 2.466;
wkf_nk = A.*wIdeal_inch.^B;

%% Mou-Deng
if E_mpsi<=1 || any(pc_psi<=500) || 0.15>lambdax || lambdax>1 || 0.004>lambdaz || lambdaz>0.5 || 0.1>sigma || sigma>0.9
    disp('Be aware that the Mou-Deng correlation is not valid for these inputs.')
end

if CL>= 0.004 % ft/sqrt(min)
    % parmeability distribution dominant case (w high LO) ---------------------
    B = 2.49;
    A = 4.48e9*(0.56*erf(0.8*sigma))^3 ...
        *(0.22*(lambdax*sigma)^2.8+0.01*((1-lambdaz)*sigma)^0.4)^0.52 ... md-ft-in^(-B)
        *(1+(1.82*erf(3.25*(lambdax-0.12))-1.31*erf(6.71*(lambdaz-0.03)))*sqrt(exp(sigma)-1)) ...
        .*exp(-(14.9-3.78.*log(sigma)-6.81.*log(E_mpsi)).*1e-4.*pc_psi);
else
    if f_c==1 || f_c==0
        % permeability distribution dominant case (w low LO) ------------------
        B = 2.43;
        A = 4.48e9*(0.2*erf(0.78*sigma))^3 ...
            *(0.22*(lambdax*sigma)^2.8+0.01*((1-lambdaz)*sigma)^0.4)^0.52 ... md-ft-in^(-B)
            *(1+(1.82*erf(3.25*(lambdax-0.12))-1.31*erf(6.71*(lambdaz-0.03)))*sqrt(exp(sigma)-1)) ...
            .*exp(-(14.9-3.78*log(sigma)-6.81*log(E_mpsi)).*1e-4.*pc_psi);
    else
        % mineralogy distribution dominant case -------------------------------
        B=2.52;
        A= 4.48e9*(0.13*f_c^0.56)^3*(1+2.97*(1-f_c)^2.02)*(0.811-0.853*f_c) ... md-ft-in^(-B)
            .*exp(-(1.2*exp(0.952*f_c)+10.5*E_mpsi^-1.823).*1e-4.*pc_psi);
    end
end
wkf_md = A.*wIdeal_inch.^B;
end % function