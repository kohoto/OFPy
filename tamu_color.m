function cc = tamu_color()
%TAMU_COLOR Summary of this function goes here
%   Detailed explanation goes here
tamu_hex_color_codes = ["B96157"; "ED998C"; "EED5C6"; "BEBEBE"; "F1F1F1"; "92CCC4"; "629B94"; "346D66"; "00413C"]; % original order in pptx template
hex_color = @(x) sscanf(x,"%2x%2x%2x",[1 3])/255;

cc = zeros(numel(tamu_hex_color_codes), 3);
for i = 1: numel(tamu_hex_color_codes)
    cc(i, :) = hex_color(tamu_hex_color_codes(i));
end

