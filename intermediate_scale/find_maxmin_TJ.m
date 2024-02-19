function find_maxmin_TJ(we_in, pc_psi)

f = @(x) get_my_cond_value(we_in, pc_psi, x);

% Define your constraints
x0 = [0.5, 0.5]; % Initial guess
lb = [0.1, 0.1]; % Lower bound
ub = [1, 1];     % Upper bound

% Find the minimum
options = optimoptions('fmincon','Display','iter');
[x_min, f_min] = fmincon(f, x0, [], [], [], [], lb, ub, [], options);

% Find the maximum by minimizing the negative of the function
f_neg = @(x) -f(x);
[x_max, f_max_neg] = fmincon(f_neg, x0, [], [], [], [], lb, ub, [], options);
f_max = -f_max_neg;

% Display the results
fprintf('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n')
fprintf('The minimum point is at x = %.2f, y = %.2f with a value of z = %.2f\n', x_min(1), x_min(2), f_min);
fprintf('The maximum point is at x = %.2f, y = %.2f with a value of z = %.2f\n', x_max(1), x_max(2), f_max);

end

function kfw = get_my_cond_value(we_in, ph_psi, x)
sdvd = x(1);
lamxd = x(2);

[A, B, C] = TJ_correlation_params(0, sdvd, lamxd);
kfw = get_conductivity(we_in, ph_psi, A, B, C);
end