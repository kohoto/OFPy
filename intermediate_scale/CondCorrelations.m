% etched width = roughness
function [kfw_NK_mdft, kfw_TJ_mdft] = CondCorrelations(w_inch, ph_psi, E, sdvd, lamxd)
[A, B, C] = NK_correlation_params(E);
kfw_NK_mdft = get_conductivity(w_inch, ph_psi, A, B, C);

[A, B, C] = TJ_correlation_params(E, sdvd, lamxd);
kfw_TJ_mdft = get_conductivity(w_inch, ph_psi, A, B, C);
end

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

function [A, B, C] = TJ_correlation_params(E, sdvd, lamxd)
    A = get_Adash(sdvd, lamxd);
    B = get_B(sdvd, lamxd);
    C = get_C2(sdvd, lamxd);
end