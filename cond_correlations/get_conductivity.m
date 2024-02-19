function kfw_mdft = get_conductivity(w_inch, ph_psi, A, B, C)
    kfw_mdft = A .* w_inch .^ B .* exp(- C .* ph_psi); % subs inch
end