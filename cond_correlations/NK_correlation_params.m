function [A, B, C] = NK_correlation_params(E_psi)
Sres_psi = 0.0201 .* E_psi - 25137;
    A = 1.476e7;
    B = 2.466;
    if 0 <= Sres_psi && Sres_psi< 2e4
        coeff = [13.9, 1.3];
    elseif Sres_psi >= 2e4
        coeff = [3.8, 0.28];
    else
        error('Sres_psi must be positive.')
    end
    C = 0.001 .* (coeff(1) - coeff(2) .* log(Sres_psi));
end