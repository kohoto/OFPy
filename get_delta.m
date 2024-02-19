function delta = get_delta(sdvd, lamxd)% sdvd: dimensionless standard deviation of roughness (denominator: 0.1 in)
% lamxd: dimensionless correlation length (denominator: 7 in)
    load('deltap_polyfit_coeffs.mat', 'pp');
    delta(1) = exp(feval(pp, [sdvd, lamxd]));

    load('deltan_polyfit_coeffs.mat', 'pp');
    delta(2) = exp(feval(pp, [sdvd, lamxd]));
end