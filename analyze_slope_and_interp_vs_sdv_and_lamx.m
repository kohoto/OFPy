function analyze_slope_and_interp_vs_sdv_and_lamx(p)
% array must be 3d and p(nsdv, nlamx, [slope, interp]).
cc = tamu_color();
lbl = my_labels();


    sdv = [0.025, 0.05, 0.075, 0.1]';
    sdvs2 = repmat(sdv, [1, 4]);
    lamx = [1, 2, 4, 6];
    lamxs2 = repmat(lamx, [4, 1]);

axs = create_tiledlayout(1, 2, 0.5);
yname = {'Slope', 'Intercept'};
yname = {'C2 [1/psi]', 'C1 [md-ft]'};
yname = {'$\beta$', '$\alpha$'};
yname = {'$B$', '$A$'};
%yname = {'q', 'p'};
for i = 1:2
    
    % FIGURE: conductivity decline curve (plot and color by lamx, axis sdv
    sdv = [0.025, 0.05, 0.075, 0.1]';
    sdvs = repmat(sdv, [1, 4]);
    lamx = [1, 2, 4, 6];
    lamxs = repmat(lamx, [4, 1]);
    % Perform surface fitting
    disp('==============================================')
    z = p(:, :, i);
    sdvs = sdvs(:);
    lamxs = lamxs(:);
    z = z(:);
    nn=2;
    sdvs(nn) = [];
    lamxs(nn) = [];
    z(nn) = [];
    [pp, gof] = fit([sdvs(:), lamxs(:)], z(:), 'poly22')

    Z_fit = feval(pp, [sdvs(:), lamxs(:)]);
    Z_fit = [Z_fit(1:nn-1); nan; Z_fit(nn:end)];
    Z_fit = reshape(Z_fit, [4, 4]);
    surf(axs(3-i), sdvs2, lamxs2, Z_fit, 'FaceColor', cc(3, :), 'FaceAlpha', 0.5, 'EdgeColor',  cc(3, :)); % Plot fitted surface
    hold(axs(3-i), 'on')
    scatter3(axs(3-i), sdvs, lamxs, z, [], cc(1, :), 'filled'); % Plot data points
    xlabel(axs(3-i), lbl.sdv, 'Interpreter', 'latex');
    ylabel(axs(3-i), lbl.lamx, 'Interpreter', 'latex');
    zlabel(axs(3-i), yname{i}, 'Interpreter', 'latex');
    legend(axs(3-i), 'Fit', 'Data');

    % Get the coefficients of the fitted equation
    %coeffs = coeffvalues(pp);    
    % Create a string to display the coefficients and R-squared value
    str = sprintf('R-squared: %f', gof.rsquare);
    % Display the string on the plot
    text(axs(3-i), max(sdvs(:)), max(lamxs(:)), max(z(:)), str, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    axs(3-i) = my_plot_format(axs(3-i));
end