import subprocess
import os
import numpy as np
from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d
import OFPy_create_dictionary


def prep_mineralogy_file(project_directory):  #For Linux and Windows (no OF command)
    """
    Implements the roughness data to blockMesh and save the new blockMesh file to '0' directory.
    Originally, blockMesh command in OF crates a box mesh without roughenss on the surface.
    Preprocess for etching simulation, add deform the frac surface using 'roguhenss' output file.
    Preprocess for conductivity simulation, we deform the frac surface points from the fracture closure calculation.

    :param project_directory:
    :type  project_directory: str
    :return:
    """

    # close = True
    # read nx, ny, size from the input file

    inp = m3d.read_input(project_directory + 'inp')

    # calc some parameters from data in inp
    # number of grids
    nx = inp["nx"]
    ny = inp["ny"]
    mean = inp["mean"]
    stdev = inp["stdev"]

    os.chdir(project_directory + "/etching")
    sim_array = gsp.GSLIB2ndarray("../roughness", 0, nx + 1, ny + 1)  # roughness file is in [inch]
    mineralogy = gsp.affine(sim_array[0], mean, stdev).T < 0
    #mineralogy = mineralogy[:-1, :-1]
    OFPy_create_dictionary.write_OF_dictionary("mineralogy", mineralogy.flatten(), note="")


if __name__ == '__main__':
    proj_dir = 'C:/Users/tohoko.tj/dissolCases/seed7500-stdev0_05/lambda1_0-0_5-stdev0_05/'
    prep_mineralogy_file(proj_dir)
