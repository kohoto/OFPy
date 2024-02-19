function slope = get_C2(sdvd, lamxd)
% sdvd: dimensionless standard deviation of roughness (denominator: 0.1 in)
% lamxd: dimensionless correlation length (denominator: 7 in)
    load('C2_polyfit_coeffs.mat', 'pp');
    slope = exp(feval(pp, [sdvd, lamxd]));
end