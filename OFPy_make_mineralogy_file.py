import subprocess
import os
import numpy as np
from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d
import write_IOObject as write


def prep_mineralogy_file(project_directory):  # For Linux and Windows (no OF command)
    """
    Implements the roughness data to blockMesh and save the new blockMesh file to '0' directory.
    Originally, blockMesh command in OF crates a box mesh without roughenss on the surface.
    Preprocess for etching simulation, add deform the frac surface using 'roguhenss' output file.
    Preprocess for conductivity simulation, we deform the frac surface points from the fracture closure calculation.

    :param project_directory: no slash at the end!
    :type  project_directory: str
    :return:
    """

    # close = True
    # read nx, ny, size from the input file

    inp = m3d.read_input(project_directory + '/inp')

    # calc some parameters from data in inp
    # number of grids
    nx = inp["nx"]
    ny = inp["ny"]
    mean = inp["mean"]
    stdev = inp["stdev"]

    # input array must be nx * ny (280 * 68)
    mineralogy_dist = 'rough'
    if mineralogy_dist == 'rough':
        os.chdir(project_directory + "/etching")
        sim_array = gsp.GSLIB2ndarray("../roughness", 0, nx + 1, ny + 1)  # roughness file is in [inch]
        mineralogy = (gsp.affine(sim_array[0], mean, stdev).T < 0.05).astype(int)
        mineralogy = mineralogy[:-1, :-1]
    elif mineralogy_dist == 'pathchy':
        # create array
        # add patchy distribution of insoluble minerals
        import cv2

        # Read the PNG image
        image = cv2.imread(project_directory + '/img.png', cv2.IMREAD_GRAYSCALE)

        # Define a insluble_mineral to separate black and white areas
        insoluble_mineral = 255  # Adjust this insluble_mineral as needed

        # Create a binary mask where black areas are 0 and white areas are 1
        mineralogy = (image != insoluble_mineral).astype(np.uint8)
        mineralogy = mineralogy[:, :-1]  # Remove one pixel in x direction

    # mineralogy = mineralogy[:-1, :-1]
    #TODO: I still need to fix the file by hand. Need to write a code for field file.
    str_list = write.write_OF_dictionary(cls="surfaceScalarField",
                                         loc="0",
                                         obj="mineralogy",
                                         dict={"internalField": 0,
                                               "boundaryField": {
                                                   "solubleWall": {
                                                       "type": "fixedValue",
                                                       "value": mineralogy.flatten().tolist()},
                                                   "solubleWall_mirrored": {
                                                       "type": "fixedValue",
                                                       "value": mineralogy.flatten().tolist()},
                                                   "inlet": {
                                                       "type": "fixedValue",
                                                       "value": 0},
                                                   "outlet": {
                                                       "type": "fixedValue",
                                                       "value": 0},
                                                   "insolubleY": {
                                                       "type": "fixedValue",
                                                       "value": 0}}})
    write.write_file(str_list, project_directory + '/etching/constant/mineralogy')


if __name__ == '__main__':
    proj_dir = 'C:/Users/tohoko.tj/dissolCases/test_patchy/rough'
    prep_mineralogy_file(proj_dir)
