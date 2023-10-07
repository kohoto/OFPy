import subprocess
import os
import numpy as np
from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d
import OFPy_create_dictionary


def prep_mineralogy_file(case_directory):  #For Linux and Windows (no OF command)
    """
    Implements the roughness data to blockMesh and save the new blockMesh file to '0' directory.
    Originally, blockMesh command in OF crates a box mesh without roughenss on the surface.
    Preprocess for etching simulation, add deform the frac surface using 'roguhenss' output file.
    Preprocess for conductivity simulation, we deform the frac surface points from the fracture closure calculation.

    :param case_directory:
    :type  case_directory: str
    :return:
    """

    # close = True
    # read nx, ny, size from the input file
    input_file_path = 'inp'


    inp_tuple = m3d.read_input(case_directory + input_file_path)
    # [image_type, file_type, dpi, Lx, Ly, Lz, cell_size, nz, height, mean, stdev, hmaj1, hmin1, seed, n_cut, ridge, ridge_height, ridge_margin] =
    inp = {"lx": inp_tuple[3], "ly": inp_tuple[4], "lz": inp_tuple[5], "dx": inp_tuple[6], "nx": int(inp_tuple[3] / inp_tuple[6]),
           "ny": int(inp_tuple[4] / inp_tuple[6]), "nz": inp_tuple[7], "lz": inp_tuple[8],
           "mean": inp_tuple[9], "stdev": inp_tuple[10], "hmaj1": inp_tuple[11], "hmin1": inp_tuple[12]}

    # calc some parameters from data in inp
    # number of grids
    nx = inp["nx"]
    ny = inp["ny"]
    mean = inp["mean"]
    stdev = inp["stdev"]

    os.chdir(case_directory + "/etching")
    sim_array = gsp.GSLIB2ndarray("../roughness", 0, nx + 1, ny + 1)  # roughness file is in [inch]
    mineralogy = gsp.affine(sim_array[0], mean, stdev).T < 0
    #mineralogy = mineralogy[:-1, :-1]
    OFPy_create_dictionary.write_OF_dictionary("mineralogy", mineralogy.flatten(), note="")


if __name__ == '__main__':
    dissolCases_directory = 'C:/Users/tohoko.tj/dissolCases/seed7500-stdev0_05/lambda1_0-0_5-stdev0_05/'
    prep_mineralogy_file(dissolCases_directory)