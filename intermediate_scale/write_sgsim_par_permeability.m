function write_sgsim_par_permeability(casepath, a_hmax, a_hmin)
% Open file for writing
fid = fopen(fullfile(casepath, 'out.txt'), 'w');

% Write contents to file
fprintf(fid, '                  Parameters for SGSIM\n');
fprintf(fid, '                  ********************\n\n');
fprintf(fid, 'START OF PARAMETERS:\n');
fprintf(fid, 'none                                  -file with data\n');
fprintf(fid, '1  2  0  3  5  0              -  columns for X,Y,Z,vr,wt,sec.var.\n');
fprintf(fid, '-1.0       1.0e21             -  trimming limits\n');
fprintf(fid, '0                             -transform the data (0=no, 1=yes)\n');
fprintf(fid, 'none.trn                     -  file for output trans table\n');
fprintf(fid, '0                             -  consider ref. dist (0=no, 1=yes)\n');
fprintf(fid, 'none.dat                  -  file with ref. dist distribution\n');
fprintf(fid, '1  2                          -  columns for vr and wt\n');
fprintf(fid, '0.0    15.0                   -  zmin,zmax(tail extrapolation)\n');
fprintf(fid, '1       0.0                   -  lower tail option, parameter\n');
fprintf(fid, '1      15.0                   -  upper tail option, parameter\n');
fprintf(fid, '1                             -debugging level: 0,1,2,3\n');
fprintf(fid, 'sgsim.dbg                     -file for debugging output\n');
fprintf(fid, '1.out                     -file for simulation output\n');
fprintf(fid, '1                             -number of realizations to generate\n');
fprintf(fid, '64    0.5    4.0              -nx,xmn,xsiz\n');
fprintf(fid, '256    0.5    1.0              -ny,ymn,ysiz\n');
fprintf(fid, '1     0.5    1.0              -nz,zmn,zsiz\n');
fprintf(fid, '4785478                        -random number seed\n');
fprintf(fid, '0     8                       -min and max original data for sim\n');
fprintf(fid, '20                            -number of simulated nodes to use\n');
fprintf(fid, '1                             -assign data to nodes (0=no, 1=yes)\n');
fprintf(fid, '0     3                       -multiple grid search (0=no, 1=yes),num\n');
fprintf(fid, '0                             -maximum data per octant (0=not used)\n');
fprintf(fid, '200.0  50.0  10.0              -maximum search radii (hmax,hmin,vert)\n');
fprintf(fid, ' 90.0   0.0   0.0              -angles for search ellipsoid\n');
fprintf(fid, '0     0.60   1.0              -ktype: 0=SK,1=OK,2=LVM,3=EXDR,4=COLC\n');
fprintf(fid, 'none.dat             -  file with LVM, EXDR, or COLC variable\n');
fprintf(fid, '4                             -  column for secondary variable\n');
fprintf(fid, '1    0.0                      -nst, nugget effect\n');
fprintf(fid, '1    1.0  90.0   0.0   0.0     -it,cc,ang1,ang2,ang3\n');
fprintf(fid, '          %d     %d  1.0     -a_hmax, a_hmin, a_vert\n', a_hmax, a_hmin);

% Close the file
fclose(fid);