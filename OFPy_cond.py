import os
import numpy as np
import platform
from GsPy3DModel import model_3D as m3d

if platform.system() == 'Windows':
       import edit_polyMesh
       import read_field
else:
       from . import edit_polyMesh
       from . import read_field


# read nx, ny, size from the input file
case_directory = '//coe-fs.engr.tamu.edu/Grads/tohoko.tj/Documents/dissolCases_230327/lambda1_0-1_0-stdev0_025'
# case_directory = '/home/tohoko/OpenFOAM/dissolFoam-v1912/dissolCases/dissolFrac_testRoughSurfGen10'


def calc_cond(case_directory):
       input_file_path = case_directory + '/inp'
       inp_tuple = m3d.read_input(input_file_path)

       inp = {"lx": inp_tuple[3], "ly": inp_tuple[4], "lz": inp_tuple[5], "dx": inp_tuple[6],
              "nx": int(inp_tuple[3] / inp_tuple[6]),
              "ny": int(inp_tuple[4] / inp_tuple[6]), "nz": inp_tuple[7], "lz": inp_tuple[8],
              "mean": inp_tuple[9], "stdev": inp_tuple[10], "hmaj1": inp_tuple[11], "hmin1": inp_tuple[12]}

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

       lines = []
       # get polyMesh from etching folder.
       os.chdir(case_directory + "/conductivity")
       last_timestep_dir = str(max([int(a) for a in os.listdir('.') if a.isnumeric()]))
       lines.append("Max timestep is: " + last_timestep_dir + ". Extract p and U from this dir.\n")

       df_points = edit_polyMesh.read_OF_points("constant/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
       df_U = read_field.read_OF_U(last_timestep_dir + "/U", nrows=nx * ny * nz)
       df_p = read_field.read_OF_p(last_timestep_dir + "/p", nrows=nx * ny * nz)

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
       avg_w = np.mean(wids)
       max_w = np.max(wids)
       lines.append('average width is {0:.5f} inch\n'.format(avg_w / 0.0254))
       lines.append('conductivity from cubic law is {0:.5e} md-ft\n'.format(avg_w * avg_w * avg_w / 12 * 1.0133e15 * 3.28084))
       lines.append('conductivity from cubic law with max width is {0:.5e} md-ft\n'.format(max_w * max_w * max_w / 12 * 1.0133e15 * 3.28084))
       q = U[0, 0, 0] * inlet_area
       # q = 50.e-6  #
       dens = 1.e3 # [kg/m3]
       # in OF, p is in [m2/s2]. It's devided by density!!
       dp = (np.average(p[0, :, :]) - np.average(p[-1, :, :])) * dens  #TODO: need to consider further since each surf area of mesh is different.
       dp_max = (np.max(p[0, :, :]) - np.min(p[-1, :, :])) * dens
	
       # compute conductivity
       mu = 0.001
       cond = q * mu * lx / dp / ly # [m3]

       # if cond file not exist, make it
       # write info = cond, etched width
       lines.append("conductivity: " + str(cond * 1.01325e15 * 3.28084) + " md-ft")
       lines.append("q: " + str(q * 60000) + " L/min\n")
       lines.append("pressure diff: " + str(dp / 6895) + " psi\n")
       lines.append("conductivity: " + str(cond * 1.01325e15 * 3.28084) + " md-ft\n")
       lines.append("max_conductivity: " + str(q * mu * lx / dp_max / ly * 1.01325e15 * 3.28084) + " md-ft\n")
       lines.append("inlet area: " + str(inlet_area) + " m2\nu_for_cond = " + str(q / inlet_area) + "m/s")
       open(case_directory + '/cond', "w").writelines(lines)


if __name__=="__main__":
       calc_cond(case_directory)
