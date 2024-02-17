function lbl = my_labels()
    lbl = struct(...
        'lamx', '$\lambda_{x} [in]$', ...
        'lamy', '$\lambda_{y} [in]$', ...
        'sdv', '$\sigma [in]$', ...
        'pc', 'Closure stress, $P_{c}$ [psi]', ...
        'kfw0', 'Zero-closure-stress conductivity, $(k_{f}w)_{0}$ [md-ft]', ...
        'kfw0_short', '$(k_{f}w)_{0}$ [md-ft]', ...
        'kfw', 'Conductivity, $k_{f}w$ [md-ft]', ...
        'we', '$w_{i} [in]$', ...
        'wa', '$\tilde{w} [in]$' ...
        );
end
