function delete_excess_files_from_acidfrac(batch_path, nlam, nsdv)

% delete excess files after running everything
for iter=1:nlam*nsdv
    ilam = ceil(iter / nlam);
    isdv = mod(iter, nsdv) + 1;

    case_dir = sprintf('k%d%d', ilam, isdv);
    casepath = fullfile(batch_path, case_dir, 'etching');
    % Define the folder path
    % List all files in the folder
    files_to_delete = [dir(fullfile(casepath, 'result*.dat')); ...
        dir(fullfile(casepath, 'suface1_0*.dat')); ...
        dir(fullfile(casepath, 'suface1_1*.dat')); ...
        dir(fullfile(casepath, 'suface1_2*.dat')); ...
        dir(fullfile(casepath, 'surface2_*.dat')); ...
        dir(fullfile(casepath, 'Surface*.dat'))];

    % Loop through the files and delete them
    for ifile = 1:length(files_to_delete)
        if isfile(fullfile(casepath, files_to_delete(ifile).name))
            delete(fullfile(casepath, files_to_delete(ifile).name));
        end
    end
end

end