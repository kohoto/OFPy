function analyze_slope_and_interp_vs_sdv_and_lamx(p, type)
% p: either 3d or 4d. [sdvs, lamxs, pcs, 1(interp) and 2(slope)]
% array must be 3d and p(nsdv, nlamx, [slope, interp]).
cc = tamu_color();
lbl = my_labels();
sdv0 = 0.1;
lx = 7;
sdv = [0.025, 0.05, 0.075, 0.1]' ./ sdv0;
sdvs = repmat(sdv, [1, 4]);
if numel(size(p)) == 4
    sdvs = repmat(sdvs, [1, 1, size(p, 3)]);
end

lamx = [1, 2, 4, 6] ./ lx;
lamxs = repmat(lamx, [4, 1]);
if numel(size(p)) == 4
    lamxs = repmat(lamxs, [1, 1, size(p, 3)]);
end
axs = create_tiledlayout(1, 2, 0.5);


if type == "C1C2" % traditional condcutivity decline curve (CDC) cefficients
    yname = {'C1 [md-ft]', 'C2 [1/psi]'};
elseif type == "alphabeta" % Modified cubic law coefficients
    yname = {'$\alpha$', '$\beta$'};
elseif type == "AB" % we vs cond/exp(-C2*sigmaC)
    yname = {"$A^{'}$", '$B$'};
elseif type == "pq"
    yname = {'p', 'q'};
else
    yname = {'Intercept', 'Slope'};
end

for i = 1:2
    
    % FIGURE: conductivity decline curve (plot and color by lamx, axis sdv

    % Perform surface fitting
    disp([yname{i}, '=============================================='])
    
    % replace bad data to nan

    p_fliped = shiftdim(p, ndims(p)-1);
    % Now operate on the first dimension, which was originally the last
    z = p_fliped(i, :, :, :)
    % (1, sdv, lam, :)
    z(1, 2, 2, :) = nan;
    z(1, 3, 2, :) = nan;
    %z(1, 3, 2, :) = nan;
    % Shift dimensions back
    p = shiftdim(p_fliped, 1);

    % data to remove
    nn=isnan(z);
    flat_sdvs = sdvs(~nn(1,:,:,:));
    flat_lamxs = lamxs(~nn(1,:,:,:));
    flat_zs = z(~nn(1,:,:,:));

    [pp, gof] = fit([flat_sdvs, flat_lamxs], flat_zs, 'poly33')
    if type == "C1C2" && i == 2  % save slope
        save('C2_polyfit_coeffs.mat', 'pp');
    end
    if type == "AB" && i == 1  % save slope
        save('Adash_polyfit_coeffs.mat', 'pp');
    end
    if type == "AB" && i == 2  % save slope
        save('B_polyfit_coeffs.mat', 'pp');
    end
    sdvs_2d = sdvs(:, :, 1);
    lamxs_2d = lamxs(:, :, 1);

    Z_fit = feval(pp, [sdvs_2d(:), lamxs_2d(:)]);

    Z_fit = reshape(Z_fit, [4, 4]);
    surf(axs(i), sdvs(:, :, 1), lamxs(:, :, 1), Z_fit, 'FaceColor', cc(3, :), 'FaceAlpha', 0.5, 'EdgeColor',  cc(3, :)); % Plot fitted surface
    hold(axs(i), 'on')
    scatter3(axs(i), sdvs(:), lamxs(:), z(:), [], cc(1, :), 'filled'); % Plot data points
    xlabel(axs(i), lbl.sdvD, 'Interpreter', 'latex');
    ylabel(axs(i), lbl.lamxD, 'Interpreter', 'latex');
    zlabel(axs(i), yname{i}, 'Interpreter', 'latex');

    % Get the coefficients of the fitted equation
    %coeffs = coeffvalues(pp);    
    % Create a string to display the coefficients and R-squared value
    str = sprintf('R^{2} = %.3f', gof.rsquare);
    % Display the string on the plot
    text(axs(i), max(sdvs(:)), max(lamxs(:)), max(z(:)), str, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    axs(i) = my_plot_format(axs(i));
end