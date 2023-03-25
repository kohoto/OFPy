import subprocess
import os
import numpy as np
from edit_polyMesh import read_OF_points
from read_field import read_OF_p, read_OF_U
import GsPy3DModel.GsPy3DModel.model_3D as m3d

# read nx, ny, size from the input file
case_directory = '/home/tohoko/OpenFOAM/dissolFoam-v1912/dissolCases/dissolFrac_testRoughSurfGen10'
input_file_path = case_directory + '/inp'


inp_tuple = m3d.read_input(input_file_path)

inp = {"lx": inp_tuple[3], "ly": inp_tuple[4], "dx": inp_tuple[5], "nx": int(inp_tuple[3] / inp_tuple[5]),
       "ny": int(inp_tuple[4] / inp_tuple[5]), "nz": 4, "lz": 0.1,
       "mean": inp_tuple[7], "stdev": inp_tuple[8], "hmaj1": inp_tuple[9], "hmin1": inp_tuple[10]}

""" calc some parameters from inputs """
# number of grids
lx = inp["lx"] * 0.0254
ly = inp["ly"] * 0.0254
lz = inp["lz"] * 0.0254
nx = inp["nx"]
ny = inp["ny"]
nz = inp["nz"]
dx = inp["dx"]
mean = inp["mean"]
stdev = inp["stdev"]
hmaj1 = inp["hmaj1"]
hmin1 = inp["hmin1"]


# get polyMesh from etching folder.
os.chdir(case_directory + "/conductivity")
last_timestep_dir = str(max([int(a) for a in os.listdir('.') if a.isnumeric()]))
print("Max timestep is: " + last_timestep_dir + ". Extract p and U from this dir.")

df_points = read_OF_points("constant/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
df_U = read_OF_U(last_timestep_dir + "/U", nrows=nx * ny * nz)
df_p = read_OF_p(last_timestep_dir + "/p", nrows=nx * ny * nz)

dx = lx / nx
dy = ly / ny
dz = lz / nz

# reshape p and U data into mesh shape
zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
p = np.transpose(df_p.to_numpy().reshape(nz, ny, nx), (2, 1, 0))
U = np.transpose(df_U['x'].to_numpy().reshape(nz, ny, nx), (2, 1, 0))

# get inlet surface area
wids = zs[0, :, -1] - zs[0, :, 0]  # get width at inlet
inlet_area = np.sum(wids) * dy


# get q. I can use a single value of U cause it will be the same everywhere due to BC.
q = U[0, 0, 0] * inlet_area

dp = np.average(p[0, :, :]) - np.average(p[-1, :, :])  #TODO: need to consider further since each surf area of mesh is different.

# compute conductivity
mu = 0.001
cond = q * mu * lx / dp / ly # [m3]

print("conductivity: " + str(cond * 1.01325e15 * 3.28084) + " md-ft")