% NOTE: pc_psi < 500 is not applicable
function [A, B, C] = MD_correlation_params(f_c, CL, E_mpsi, sigma, lambdax, lambdaz)
%% Mou-Deng
if E_mpsi<=1 || 0.15>lambdax || lambdax>1 || 0.004>lambdaz || lambdaz>0.5 || 0.1>sigma || sigma>0.9
    disp('Be aware that the Mou-Deng correlation is not valid for these inputs.')
end

if CL>= 0.004 % ft/sqrt(min)
    % parmeability distribution dominant case (w high LO) ---------------------
    B = 2.49;
    A = 4.48e9*(0.56*erf(0.8*sigma))^3 ...
        *(0.22*(lambdax*sigma)^2.8+0.01*((1-lambdaz)*sigma)^0.4)^0.52 ... md-ft-in^(-B)
        *(1+(1.82*erf(3.25*(lambdax-0.12))-1.31*erf(6.71*(lambdaz-0.03)))*sqrt(exp(sigma)-1)); ...
    C = (14.9-3.78.*log(sigma)-6.81.*log(E_mpsi)).*1e-4;
else
    if f_c==1 || f_c==0
        % permeability distribution dominant case (w low LO) ------------------
        B = 2.43;
        A = 4.48e9*(0.2*erf(0.78*sigma))^3 ...
            *(0.22*(lambdax*sigma)^2.8+0.01*((1-lambdaz)*sigma)^0.4)^0.52 ... md-ft-in^(-B)
            *(1+(1.82*erf(3.25*(lambdax-0.12))-1.31*erf(6.71*(lambdaz-0.03)))*sqrt(exp(sigma)-1)); % ...
        C = (14.9-3.78*log(sigma)-6.81*log(E_mpsi)).*1e-4;
    else
        % mineralogy distribution dominant case -------------------------------
        B=2.52;
        A= 4.48e9*(0.13*f_c^0.56)^3*(1+2.97*(1-f_c)^2.02)*(0.811-0.853*f_c); % ... md-ft-in^(-B)
        C = (1.2*exp(0.952*f_c)+10.5*E_mpsi^-1.823).*1e-4;
    end
end

end