import os
import shutil
import decimal
import numpy as np
from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d
import matplotlib.pyplot as plt
plt.style.use("tamu_style")
# STEP 1
# this is to use from Windows pc. (Linux doens't have plot support)


def make_case(lx, ly, lz, cellsize, nz, lambda_xs, lambda_ys, stdevs, seed):
    """
    Create a set of random width distributions for various correlation length.
    Variance will be the same for all.
    :return: 'roughness' output file
    """
    dissolCases_directory = 'C:/Users/tohoko.tj/dissolCases/seed' + str(seed)\
                            + '-stdev' + str(stdevs[0]).replace('.', '_') + '/'
    if not os.path.exists(dissolCases_directory):
        os.mkdir(dissolCases_directory)
    lambda_xs, lambda_ys, stdevs = np.meshgrid(lambda_xs, lambda_ys, stdevs)

    # create inp files and dir for it first
    for lambda_x, lambda_y, stdev in zip(lambda_xs.flatten(), lambda_ys.flatten(), stdevs.flatten()):
        inp = ["image_type file_type dpi # by default, white space is the separator\n",
               "{} {} {}\n".format('tif', 'stl', 600),
               "Lx [in], Ly [in], Lz [in], cellsize [in], nz, height [in], mean [in], stdev [in]\n",
               "{} {} {} {} {} {} {} {}\n".format(lx, ly, lz, cellsize, nz, 0.0, 0.0, stdev),
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
    """
    Generate roughness data using GSLIB and input data from 'inp'
    :param case_name: a single case name
    :return: 'roughness' output file
    """
    inp = m3d.read_input(case_name + '/inp')

    # number of grids
    lx = inp["lx"] * 0.0254
    ly = inp["ly"] * 0.0254
    lz = inp["lz"] * 0.0254
    nx = inp["nx"]
    ny = inp["ny"]
    dx = inp["dx"]
    mean = inp["mean"]
    stdev = inp["stdev"]
    hmaj1 = inp["hmaj1"]
    hmin1 = inp["hmin1"]
    seed = inp["seed"]


    # Make a truth model / unconditional simulation
    var = gsp.make_variogram(nug=0.0, nst=1, it1=1, cc1=1.0, azi1=90.0, hmaj1=hmaj1, hmin1=hmin1)
    # write a width distribution on 'roughness' file
    width = gsp.GSLIB_sgsim_2d_uncond(1, nx, ny, dx, seed + 3, var, 'roughness')

    # copy input files in the project directory for reference
    shutil.copyfile('GsPy3DModel/sgsim.par', case_name + '/sgsim.par')
    shutil.copyfile('GsPy3DModel/roughness', case_name + '/roughness')

    # since we have output file ('roughness'), the output array is used just for plotting.
    width = gsp.affine(width, mean, stdev)  #TODO: how does stdev work? I don't need this, since it's dealt later.
    decimal.getcontext().prec = 1
    gsp.pixelplt(width, 0, lx + dx, 0, ly + dx, dx, -0.5, 0.5,
                 '', 'x [in]', 'y [in]', 'height', plt.cm.jet, case_name)

    # show historam of prior distribution
    fig, axs = plt.subplots(figsize=(7.5, 5))
    count, bins, ignored = axs.hist(width.flatten(), 30)
    a = np.sqrt(np.sum(width * width) / len(width.flatten()))
    axs.axvline(a, color=(240.0/256, 130.0/256, 33.0/256), linewidth=1.5)
    axs.axvline(-a, color=(240.0 / 256, 130.0 / 256, 33.0 / 256), linewidth=1.5)
    axs.axvline(0, color='k', linewidth=1.5)
    axs.set_ylim([0, 2500])
    axs.set_xlim([-0.3, 0.3])
    for tick in axs.get_xticklabels():
        tick.set_fontname("Segoe UI")
    for tick in axs.get_yticklabels():
        tick.set_fontname("Segoe UI")
    fig.tight_layout()
    plt.show()


if __name__ == "__main__":
    inp_seed = 6000
    # use a single standard deviation (but make it into an array just for np.meshgrid)
    inp_stdev = np.array([0.05])

    # 21 combinations of lambda_x, lambda_y
    make_case(lx=7.0, ly=1.7, lz=0.1,
              cellsize=0.025, nz=10,
              lambda_xs=np.round(np.arange(1.0, 6.1, 1.0), 3),
              lambda_ys=np.round(np.arange(0.5, 1.51, 0.5), 3),
              stdevs=inp_stdev, seed=inp_seed)
