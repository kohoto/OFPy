function delete_execution_files(batch_path, nlam, nsdv)

% delete excess files after running everything
for iter=1:nlam*nsdv
    ilam = ceil(iter / nlam);
    isdv = mod(iter, nsdv) + 1;

    case_dir = sprintf('k%d%d', ilam, isdv);
    casepath = fullfile(batch_path, case_dir, 'etching');
    delete(fullfile(casepath, "Acid_Fracturing.exe"));
end

end