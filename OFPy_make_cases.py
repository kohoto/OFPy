import os
import shutil

import numpy as np
from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d

# this is to use from windows pc.

dissolCases_directory = '//coe-fs.engr.tamu.edu/Grads/tohoko.tj/Documents/seed7500-stdev0_15/'


def main():
    Lx = 7.0; Ly = 1.7; Lz = 0.1; cellsize = 0.025; nz = 10

    seed = 7500
    # stdevs = np.array([0.0125, 0.025, 0.05, 0.075, 0.1, 0.125, 0.15])
    stdevs = np.array([0.15])
    lambda_xs = np.round(np.arange(1.0, 6.1, 1.0), 3)
    lambda_ys = np.round(np.arange(0.5, 1.51, 0.5), 3)
    lambda_xs, lambda_ys, stdevs = np.meshgrid(lambda_xs, lambda_ys, stdevs)

    # create inp files and dir for it first
    for lambda_x, lambda_y, stdev in zip(lambda_xs.flatten(), lambda_ys.flatten(), stdevs.flatten()):
        inp = ["image_type file_type dpi # by default, white space is the separator\n",
               "{} {} {}\n".format('tif', 'stl', 600),
               "Lx [in], Ly [in], Lz [in], cellsize [in], nz, height [in], mean [in], stdev [in]\n",
               "{} {} {} {} {} {} {} {}\n".format(Lx, Ly, Lz, cellsize, nz, 0.0, 0.0, stdev),
               "corr_x [in], corr_y [in], seed\n", # random number seed  for stochastic simulation
               "{} {} {}\n".format(lambda_x, lambda_y, seed),
               "ncut_x ncut_y\n",
               "{} {}\n".format(1, 1),
               "ridge, ridge_height [in], ridge_margin [in]\n",
               "{} {} {}\n".format(0, 0.1, 0.0)]

        case_name = 'lambda' + str(lambda_x).replace('.', '_') + '-' + str(lambda_y).replace('.', '_') + '-stdev' + str(stdev).replace('.', '_')
        path = dissolCases_directory + case_name
        if not os.path.exists(path):
            os.mkdir(path)
        # create input file in the created directory
        open(path + '/inp', "w").writelines(inp)
        make_roughness(dissolCases_directory + case_name)
        print(str(len(lambda_xs.flatten())) + ' cases are generated in ' + dissolCases_directory + '!')


def make_roughness(case_name):
    input_file_path = '/inp'

    [image_type, file_type, dpi, Lx, Ly, Lz, cell_size, nz, height, mean, stdev, hmaj1, hmin1, seed, n_cut, ridge, ridge_height, ridge_margin] = m3d.read_input(case_name + input_file_path)

    # number of grids
    nx = int(Lx / cell_size) + 1
    ny = int(Ly / cell_size) + 1

    # Make a truth model / unconditional simulation
    var = gsp.make_variogram(nug=0.0, nst=1, it1=1, cc1=1.0, azi1=90.0, hmaj1=hmaj1, hmin1=hmin1)
    width = gsp.GSLIB_sgsim_2d_uncond(1, nx, ny, cell_size, seed + 3, var, 'roughness')
    shutil.copyfile('GsPy3DModel/sgsim.par', case_name + '/sgsim.par')
    shutil.copyfile('GsPy3DModel/roughness', case_name + '/roughness')
    # gsp.affine(width, mean, stdev)  #TODO: how does stdev work? I don't need this, since it's dealt later.


if __name__ == "__main__":
    main()