function A = get_Adash(sdvd, lamxd)% sdvd: dimensionless standard deviation of roughness (denominator: 0.1 in)
% lamxd: dimensionless correlation length (denominator: 7 in)
    load('Adash_polyfit_coeffs.mat', 'pp');
    A = feval(pp, [sdvd, lamxd]);
end

function B = get_B(sdvd, lamxd)% sdvd: dimensionless standard deviation of roughness (denominator: 0.1 in)
% lamxd: dimensionless correlation length (denominator: 7 in)
    load('B_polyfit_coeffs.mat', 'pp');
    B = feval(pp, [sdvd, lamxd]);
end