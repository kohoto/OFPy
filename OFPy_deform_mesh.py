import subprocess
import os
import time
import platform

from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d
if platform.system() == 'Windows':
    import edit_polyMesh
    import deform_blockMesh
else:
    from . import edit_polyMesh
    from . import deform_blockMesh

def prep_case(case_directory, close):  #For Linux and Windows (no OF command)
    """
    Implements the roughness data to blockMesh and save the new blockMesh file to '0' directory.
    Originally, blockMesh command in OF crates a box mesh without roughenss on the surface.
    Preprocess for etching simulation, add deform the frac surface using 'roguhenss' output file.
    Preprocess for conductivity simulation, we deform the frac surface points from the fracture closure calculation.

    :param case_directory:
    :type  case_directory: str
    :param close:
    :type  close: bool
    :return:
    """

    initial_dir = os.getcwd()
    if close:
        print('Preparing mesh for ' + case_directory + 'closure')
    else:
        print('Preparing mesh for ' + case_directory + 'etching')

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
    lx = inp["lx"]
    ly = inp["ly"]
    lz = inp["lz"]
    nx = inp["nx"]
    ny = inp["ny"]
    nz = inp["nz"]
    dx = inp["dx"]
    mean = inp["mean"]
    stdev = inp["stdev"]
    hmaj1 = inp["hmaj1"]
    hmin1 = inp["hmin1"]

    if close:
        # get polyMesh from etching folder.
        last_timestep_dir = str(max([int(a) for a in os.listdir(case_directory + '/etching') if a.isnumeric()]))
        print("Max timestep is: " + last_timestep_dir + ". Copy this mesh to conductivity simulation.")

        # copy mesh from etching project dir to conductivity project dir
        pcs = [pc * 1000 for pc in list(range(1, 4))]
        for pc in pcs:
            os.chdir(case_directory + "/conductivity" + str(pc))
            os.system(
                "mkdir constant/polyMesh; cp -r ../etching/constant/polyMesh constant; cp ../etching/" + last_timestep_dir + "/polyMesh/points constant/polyMesh/points")

    else:
        # run blockMesh and polyMesh

        os.chdir(case_directory + "/etching")
        # print("Run dissolFoam case at {0}".format(os.getcwd()))

        # rewrite system/blockMeshDict
        blockMeshDict = "system/blockMeshDict"
        blockMeshDict_new = "system/blockMeshDict_new"
        with open(blockMeshDict, "r") as f, open(blockMeshDict_new, "w+") as f_new:
            lines = []
            while True:
                lines.append(f.readline())
                if not lines[-1]:
                    break
                if 'blocks' in lines[-1].split():
                    lines.append(f.readline())  # read "("
                    blocks = f.readline()
                    pha = [i for i, letter in enumerate(blocks) if letter == '('][1]  # find the second (
                    pha2 = [i for i, letter in enumerate(blocks) if letter == ')'][1]  # find the second )
                    blocks = blocks[:pha + 1] + str(nx) + " " + str(ny) + " " + str(nz) + blocks[
                                                                                          pha2:]  # rewrite number of cells in each dir
                    lines.append(blocks)

            f_new.writelines(lines)

        os.system("rm " + blockMeshDict + "; mv " + blockMeshDict_new + " " + blockMeshDict)

        sim_array = gsp.GSLIB2ndarray("../roughness", 0, nx + 1, ny + 1)  # roughness file is in [inch]
        roughness = gsp.affine(sim_array[0], mean, stdev).T

    start = time.time()
    # df_points = edit_polyMesh.read_OF_points(f"conductivity/{}/polyMesh/points".int(num), nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_points = edit_polyMesh.read_OF_points("constant/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_points['index_column'] = df_points.index

    if close:
        for pc in pcs:
            os.chdir(case_directory + "/conductivity" + str(pc))
            df_points_deformed = deform_blockMesh.deform_blockMesh(inp, df_points)
            edit_polyMesh.write_OF_polyMesh('points', len(df_points_deformed), df_points_deformed)  # write new mesh in constant/polyMesh/

    else:
        df_points_deformed = deform_blockMesh.deform_blockMesh(inp, df_points, roughness=roughness)  # roughness file is in [inch]
        edit_polyMesh.write_OF_polyMesh('points', len(df_points_deformed), df_points_deformed)  # write new mesh in constant/polyMesh/

    end = time.time()
    print("elapsed time: " + str(end - start) + " s")

    #TODO: check mesh. If I'm not running it here, then where I run checkMesh?

    # for Lenovo linux
    # if close:
    #     sp2 = subprocess.Popen("source $WM_PROJECT_DIR/etc/bashrc;"
    #                            ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
    #                            " runApplication checkMesh -allGeometry -allTopology;"
    #                            , shell=True, executable='/bin/bash')
    # else:
    #     sp2 = subprocess.Popen("source $WM_PROJECT_DIR/etc/bashrc;"
    #                            ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
    #                            " runApplication checkMesh -allGeometry -allTopology;"
    #                            "mkdir 0/polyMesh;"
    #                            "cp -r constant/polyMesh/points 0/polyMesh/points;"
    #                            , shell=True, executable='/bin/bash')
    
    # for grace
    # os.system('checkMesh -allGeometry -allTopology')

    if not close:
        if not os.path.exists('0/polyMesh'):
            os.makedirs('0/polyMesh')
        os.system('cp -r constant/polyMesh/points 0/polyMesh/points')

    os.chdir(initial_dir)
