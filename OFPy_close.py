import subprocess
import os
import time
import signal
from edit_polyMesh import write_OF_polyMesh, read_OF_points, read_OF_boundary
from deform_blockMesh import deform_blockMesh
import GsPy3DModel.GsPy3DModel.geostatspy as gsp
import GsPy3DModel.GsPy3DModel.model_3D as m3d

close = True
# read nx, ny, size from the input file
input_file_path = '/inp'
save_parent_dir = 'output/'
case_directory = '/scratch/user/tohoko.tj/dissolCases/dissolFrac_testRoughSurfGen16'



sp3 = subprocess.Popen("module load GCC/8.3.0 OpenMPI/3.1.4; module load OpenFOAM/v1912; source ${FOAM_BASH};"
                       ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
                       , shell=True, executable='/bin/bash')
sp3.communicate()


WM_PROJECT_DIR = os.getenv('WM_PROJECT_DIR')


inp_tuple = m3d.read_input(case_directory + input_file_path)

inp = {"lx": inp_tuple[3], "ly": inp_tuple[4], "dx": inp_tuple[5], "nx": int(inp_tuple[3] / inp_tuple[5]),
       "ny": int(inp_tuple[4] / inp_tuple[5]), "nz": 10, "lz": 0.1,
       "mean": inp_tuple[7], "stdev": inp_tuple[8], "hmaj1": inp_tuple[9], "hmin1": inp_tuple[10]}

""" calc some parameters from inputs """
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
    os.chdir(case_directory + "/conductivity")
    last_timestep_dir = str(max([int(a) for a in os.listdir('../etching') if a.isnumeric()]))
    print("Max timestep is: " + last_timestep_dir + ". Copy this mesh to conductivity simulation.")

    # copy mesh from etching project dir to conductivity project dir
    os.system("mkdir constant/polyMesh; cp -r ../etching/constant/polyMesh constant; cp ../etching/" + last_timestep_dir + "/polyMesh/points constant/polyMesh/points")

else:
    # run blockMesh and polyMesh

    os.chdir(case_directory + "/etching")
    print("Run dissolFoam case at {0}".format(os.getcwd()))

    # rewrite system/blockMeshDict
    blockMeshDict =  "system/blockMeshDict"
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
                pha = [i for i, letter in enumerate(blocks) if letter == '('][1] # find the second (
                pha2 = [i for i, letter in enumerate(blocks) if letter == ')'][1] # find the second )
                blocks = blocks[:pha+1] + str(nx) + " " + str(ny) + " " + str(nz) + blocks[pha2:]  # rewrite number of cells in each dir
                lines.append(blocks)

        f_new.writelines(lines)

    os.system("rm " + blockMeshDict + "; mv " + blockMeshDict_new + " " + blockMeshDict)


    # generate smooth mesh, topoSet, and initial conditions
    sp = subprocess.Popen("source " + WM_PROJECT_DIR + "/etc/bashrc;"
                                                       ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
                                                       " runApplication blockMesh;"
                                                       "runApplication topoSet -constant; cp -rp Zero 0;"
                          , shell=True, executable='/bin/bash')
    sp.communicate()
    sim_array = gsp.GSLIB2ndarray("../roughness", 0, nx + 1, ny + 1)  # roughness file is in [inch]
    roughness = gsp.affine(sim_array[0], mean, stdev).T

start = time.time()
# df_points = read_OF_points(f"conductivity/{}/polyMesh/points".int(num), nrows=(nx + 1) * (ny + 1) * (nz + 1))
df_points = read_OF_points("constant/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
df_points['index_column'] = df_points.index

if close:
    df_points = deform_blockMesh(inp, df_points)
else:
    df_points = deform_blockMesh(inp, df_points, roughness=roughness)  # roughness file is in [inch]

write_OF_polyMesh('points', len(df_points), df_points)
end = time.time()

print("elapsed time: " + str(end - start) + " s")

if close:
    sp2 = subprocess.Popen("source " + WM_PROJECT_DIR + "/etc/bashrc;"
                                                        ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
                                                        " runApplication checkMesh -allGeometry -allTopology;"
                                                        "paraFoam"
                           , shell=True, executable='/bin/bash')
else:
    sp2 = subprocess.Popen("source " + WM_PROJECT_DIR + "/etc/bashrc;"
                                                       ". $WM_PROJECT_DIR/bin/tools/RunFunctions;"
                                                       " runApplication checkMesh -allGeometry -allTopology;"
                                                       "mkdir 0/polyMesh;"
                                                       "cp -r constant/polyMesh/points 0/polyMesh/points;"
                           "paraFoam"
                          , shell=True, executable='/bin/bash')
sp2.communicate()
