import numpy as np
import scipy as sp
import pandas as pd
import platform
import math as m
if platform.system() == 'Windows':
    from plotly.subplots import make_subplots
    import plotly.graph_objects as go


def deform_blockMesh(inp, df_points, roughness=None, pc=1000):  # this
    """
    This function change the geometry of a blockMesh.
    :param inp: inp file path
    :type inp: str
    :param df_points: original distribution of points (etching: flat surface, conductivity: roughness after etching)
    :type df_points: pd.DataFrame
    :param roughness: [optional] sparate 'roughness' input file
    :type roughness: str (file name only, mostly its name is 'roughness')
    :return: new distribution of points which will be wrtiten in 'points'.
    """
    if roughness is None:
       close = True
       youngs_modulus = 1e6  # psi
    else:
        close = False
        roughness *= 0.0254

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
    ratios = np.arange(1, - 1/nz, -1/nz)

    zs = np.transpose(df_points['z'].to_numpy().reshape(nz+1, ny+1, nx+1), (2, 1, 0))

    wids = zs[:, :, -1] - zs[:, :, 0]  # top surface - btm surface
    if close:
        print("working on pc = " + str(pc) + ", average width of original opening is " + str(np.average(wids)))
        wids_by_col = np.sum(wids, axis=1) / (ny + 1)  # average width of each column
        wids_by_col -= np.min(wids_by_col)  # getting waviness
        wids -= (np.ones((ny + 1, nx + 1)) * wids_by_col).T

        min_disp = np.min(wids)
        wid_threshold = 0.01 * min_disp  # put it here so that threshold won't change with min_disp

        if pc > 0:
            disp = sp.optimize.minimize_scalar(f, args=(wids, np.max(wids) - np.min(wids), youngs_modulus, dx, dy, 48 * pc),  # load in N
                                          bounds=(np.min(wids), np.max(wids)), tol=1e-6, method='bounded')
            print(disp)
            # get new width
            wids = (wids - disp.x) * ((wids - disp.x) > wid_threshold) + wid_threshold * ((wids - disp.x) <= wid_threshold)

        else:
            # calculate wids distribution when the min wid point touched
            # NOTE: though this point should have 0 wids, to make CFD work, we keep 1% of its original wids
            wids -= np.tile(0.99 * min_disp, (ny+1, 1)).T

        if platform.system() == 'Windows':
            # show the contour of fracture opening
            # np.where... is not to show the closed points in plot
            fig = make_subplots(rows=2, cols=1, )

            fig.add_trace(
                go.Heatmap(z=np.where(wids.T == wid_threshold, np.nan, wids.T), connectgaps=False, dx=dx, dy=dy),
                row=1, col=1
            )
            fig.update_yaxes(anchor="x")
            # plot CDF of the wids dist
            hist, bin_edges = np.histogram(np.where(wids.T == 0.01 * min_disp, 0.0, wids.T), bins=100, density=True)
            cdf = np.cumsum(hist * np.diff(bin_edges))
            fig.add_trace(
                go.Scatter(x=bin_edges, y=cdf, name='CDF'),
                row=2, col=1
            )
            fig.show()

    else:  # shift
        zs[:, :, -1] += roughness

    # getting internal points z coordinates
    for i in range(nz+1):
        zs[:, :, i] = zs[:, :, -1] - wids * ratios[i]

    xs = np.tile(x_coords, (nz+1, ny+1, 1))
    ys = np.tile(y_coords, (nz+1, nx+1, 1))

    xs = xs.reshape(-1)
    ys = np.transpose(ys, (0, 2, 1)).reshape(-1)
    zs = np.transpose(zs, (2, 1, 0)).reshape(-1)

    coords = np.vstack((xs, ys, zs)).T
    return pd.DataFrame(data=coords, columns=['x', 'y', 'z'])


def f(disp, wids, max_disp, youngs_modulus, dx, dy, load):
    disp_at_pts = abs(wids - disp) * ((wids - disp) <= 0)

    # from the displacement and Young's modulus, get the pressure at the point
    stress = (disp_at_pts / max_disp) * youngs_modulus  # 4.0 is rock height for the both sides

    # calculate the force
    load_calc = np.sum(stress * 6894.76 * dx * dy)

    # if the force is the same as my input, return, if not, change the displacement by * F / calced force

    return abs((load_calc - load) / load)


if __name__ == "__main__":
    # testing the closure function with closure pressure
    from GsPy3DModel import model_3D as m3d
    import os
    import edit_polyMesh

    case_directory = 'C:/Users/tohoko.tj/dissolCases/test_close/lambda1_0-0_5-stdev0_025'

    # read nx, ny, size from the input file
    input_file_path = '/inp'

    inp = m3d.read_input(case_directory + input_file_path)
    # calc some parameters from data in inp
    nx = inp["nx"]
    ny = inp["ny"]
    nz = inp["nz"]

    os.chdir(case_directory + "/etching")
    last_timestep_dir = str(max([int(a) for a in os.listdir('../etching') if a.isnumeric()]))
    print("Max timestep is: " + last_timestep_dir + ". Copy this mesh to conductivity simulation.")

    df_points = edit_polyMesh.read_OF_points(last_timestep_dir + "/polyMesh/points",
                                             nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_points['index_column'] = df_points.index

    pcs = [pc * 1000 for pc in list(range(5))]
    for pc in pcs:
        zzs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
        print("avg width of original opening: " + str(np.average(zzs[:, :, -1] - zzs[:, :, 0])))

        deform_blockMesh(inp, df_points.copy(), roughness=None, pc=pc)