function [A, B, C] = TJ_correlation_params(E_psi, sdvd, lamxd)
    A = get_Adash(sdvd, lamxd);
    B = get_B(sdvd, lamxd);
    C = get_C2(sdvd, lamxd);
end