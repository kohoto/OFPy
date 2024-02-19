function A = get_Adash(sdvd, lamxd)% sdvd: dimensionless standard deviation of roughness (denominator: 0.1 in)
% lamxd: dimensionless correlation length (denominator: 7 in)
    load('Adash_polyfit_coeffs.mat', 'pp');
    A = exp(feval(pp, [sdvd, lamxd]));
end

