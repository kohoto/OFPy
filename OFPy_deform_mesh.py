import subprocess
import os
import time
import platform
import numpy as np
import json

from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d

if platform.system() == 'Windows':
    import edit_polyMesh
    import deform_blockMesh
else:
    from . import edit_polyMesh
    from . import deform_blockMesh


def prep_case(case_directory, close):  # For Linux and Windows (no OF command)
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

    start = time.time()
    initial_dir = os.getcwd()
    if close:
        print('Preparing mesh for ' + case_directory + '/conductivity')
        # get polyMesh from etching folder.
        last_timestep_dir = str(max([int(a) for a in os.listdir(case_directory + '/etching') if a.isnumeric()]))
        print("Max timestep is: " + last_timestep_dir + ". Copy this mesh to conductivity simulation.")
        orig_points_path = case_directory + '/etching/' + last_timestep_dir + '/polyMesh/points'
    else:
        print('Preparing mesh for ' + case_directory + '/etching')
        orig_points_path = case_directory + '/etching/constant/polyMesh/points'


    # read nx, ny, size from the input file
    inp = m3d.read_input(case_directory + '/inp')

    # calc some parameters from data in inp
    # number of grids
    lx = inp["lx"]
    ly = inp["ly"]
    lz = inp["lz"] * 0.0254  # inch => m
    nx = inp["nx"]
    ny = inp["ny"]
    nz = inp["nz"]
    dx = inp["dx"] * 0.0254
    dy = inp["dx"] * 0.0254
    mean = inp["mean"]
    stdev = inp["stdev"]
    hmaj1 = inp["hmaj1"]
    hmin1 = inp["hmin1"]
    seed = inp["seed"]

    df_points = edit_polyMesh.read_OF_points(orig_points_path, nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_points['index_column'] = df_points.index


    if close:
        # compute paramters independent to pc and write cond.json file
        zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
        wids = zs[:, :, -1] - zs[:, :, 0]
        etched_wids = wids.reshape(-1) - lz  # lz is the original frac opening
        details = {
            'seed': seed,
            'lambda_x__in': hmaj1,
            'lambda_z__in': hmin1,
            'stdev': stdev,
            'etched_vol__in3': 61023.7 * dx * dy * np.sum(etched_wids),  # 61023.7 is m3 -> in3
            'wid_e__in': np.mean(etched_wids) / 0.0254
            #TODO: get statistical parameters of widths distribution
        }
        open(case_directory + '/cond.json', 'w').write(json.dumps(details, indent=4))


        # copy mesh from etching project dir to each conductivity dir
        pcs = [pc * 1000 for pc in list(range(5))]
        for pc in pcs:
            os.chdir(case_directory + "/conductivity" + str(pc))  #these directory already exist from prepBatch
            os.system(
                "mkdir -p constant/polyMesh; "  # create directory if not exist
                "cp -r ../etching/constant/polyMesh constant; ")    # copy all mesh related files

            df_points_deformed = deform_blockMesh.deform_blockMesh(inp, df_points, pc=pc)
            edit_polyMesh.write_OF_polyMesh('points', len(df_points_deformed), # current directory must be conductivity1000 etc
                                            df_points_deformed)  # write new mesh in constant/polyMesh/

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

        df_points_deformed = deform_blockMesh.deform_blockMesh(inp, df_points,
                                                               roughness=roughness)  # roughness file is in [inch]
        edit_polyMesh.write_OF_polyMesh('points', len(df_points_deformed),
                                        df_points_deformed)  # write new mesh in constant/polyMesh/
        # finally, copy mesh to 0
        os.system('mkdir -p 0/polyMesh; cp -r constant/polyMesh/points 0/polyMesh/points')

    print("Elapsed time: " + str(time.time() - start) + " s")
    '''
    # for Lenovo linux
    sp2 = subprocess.Popen("source $WM_PROJECT_DIR/etc/bashrc;"
                           ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
                           " runApplication checkMesh -allGeometry -allTopology;"
                           , shell=True, executable='/bin/bash')
    '''
    os.chdir(initial_dir)


# close a fracture for the all projects in 'batch_directory' all at once.
if __name__ == "__main__":
    dissolCases_dir = 'C:/Users/tohoko.tj/dissolCases/no_roughness_mineralogy/no_roughness'
    # get polyMesh from etching folder.
    os.chdir(dissolCases_dir)
    dir_list = os.listdir(dissolCases_dir)

    # run case
    for proj in dir_list:
        prep_case(proj, close=True)
