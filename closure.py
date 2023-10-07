import numpy as np
import scipy as sp
import os
import pandas as pd
from GsPy3DModel import model_3D as m3d
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import edit_polyMesh
import platform

if platform.system() == 'Windows':
    import read_field
else:
    from . import read_field


def close(inp, df_points):
    lx = inp["lx"] * 0.0254
    ly = inp["ly"] * 0.0254
    lz = inp["lz"] * 0.0254
    nx = inp["nx"]  # nx is number of faces, not points
    ny = inp["ny"]
    nz = inp["nz"]

    dx = lx / nx
    dy = ly / ny
    dz = lz / nz

    x_coords = np.arange(0, lx + 0.0001, dx)
    y_coords = np.arange(0, ly + 0.0001, dy)
    ratios = np.arange(1, - 1 / nz, -1 / nz)

    zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))

    wids = zs[:, :, -1] - zs[:, :, 0]  # top surface - btm surface


    # assume disp
    youngs_modulus = 1e6  # psi
    load = 96 * 1000  # N
    min_disp = np.min(wids)  # in inch
    max_disp = np.max(wids)

    sol = sp.optimize.minimize_scalar(f, args=(wids, max_disp, youngs_modulus, dx, dy, load),
                                      bounds=(min_disp, max_disp), method='bounded')
    # plot disp distribution
    wids_closed = (wids - sol.x) * ((wids - sol.x) > 0)
    plt.title("Width at " + str(load / 1000) + " kN")
    plt.contourf(wids_closed / 0.0254)
    plt.colorbar()
    plt.show()


    # plot stress distribution
    strain_closed = abs(wids - sol.x) * ((wids - sol.x) <= 0) / max_disp
    plt.title("Stress [psi]")
    plt.contourf(strain_closed * youngs_modulus)
    plt.colorbar()
    plt.show()


def f(disp, wids, max_disp, youngs_modulus, dx, dy, load):
    disp_at_pts = abs(wids - disp) * ((wids - disp) <= 0)

    # from the displacement and Young's modulus, get the pressure at the point
    stress = (disp_at_pts / max_disp) * youngs_modulus  # 4.0 is rock height for the both sides

    # TODO: get the pressure around the contact point
    # calculate the force
    load_calc = np.sum(stress * 6894.76 * dx * dy)

    # if the force is the same as my input, return, if not, change the displacement by * F / calced force
    return abs((load_calc - load) / load)


if __name__ == "__main__":
    case_directory = 'C:/Users/tohoko.tj/dissolCases/seed2000-stdev0_05/lambda1_0-0_5-stdev0_05'

    # read nx, ny, size from the input file
    input_file_path = '/inp'

    inp_tuple = m3d.read_input(case_directory + input_file_path)
    inp = {"lx": inp_tuple[3], "ly": inp_tuple[4], "lz": inp_tuple[5], "dx": inp_tuple[6],
           "nx": int(inp_tuple[3] / inp_tuple[6]),
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

    os.chdir(case_directory + "/etching")
    last_timestep_dir = str(max([int(a) for a in os.listdir('../etching') if a.isnumeric()]))
    print("Max timestep is: " + last_timestep_dir + ". Copy this mesh to conductivity simulation.")

    df_points = edit_polyMesh.read_OF_points(last_timestep_dir + "/polyMesh/points",
                                             nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_points['index_column'] = df_points.index

    close(inp, df_points)
