import numpy as np
import scipy as sp
import pandas as pd
import platform
if platform.system() == 'Windows':
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
        youngs_modulus = 1e6  # psi
        load = 48 * pc  # N
        min_disp = np.min(wids)  # in inch
        max_disp = np.max(wids)

        disp = sp.optimize.minimize_scalar(f, args=(wids, max_disp, youngs_modulus, dx, dy, load),
                                          bounds=(min_disp, max_disp), method='bounded')

        # calculate wids distribution when the min wid point touched
        # NOTE: though this point should have 0 wids, to make CFD work, we keep 1% of its original wids
        # min_width = 0.99 * min_disp
        # wids -= min_width

        # shift top surface according to the disp solution
        zs[:, :, -1] -= 0.5 * disp.x
        # get new width
        wids = (wids - disp.x) * ((wids - disp.x) > 0) + 0.01 * min_disp * ((wids - disp.x) <= 0)
        np.savetxt("wids.csv", wids / 0.0254, delimiter=",")

        if platform.system() == 'Windows':
            # show the contour of fracture opening
            layout = go.Layout(title="Width distribution at Pc = {} Pa".format(pc), yaxis_scaleanchor="x")
            # np.where... is not to show the closed points in plot
            fig = go.Figure(
                data=[go.Heatmap(z=np.where(wids.T == 0.01 * min_disp, np.nan, wids.T), connectgaps=False, dx=dx, dy=dy)],
                layout=layout)
            fig.show()

            # plot CDF of the wids dist
            layout = go.Layout(title="Width distribution at Pc = {} Pa".format(pc), yaxis_scaleanchor="x")
            hist, bin_edges = np.histogram(np.where(wids.T == 0.01 * min_disp, 0.0, wids.T), bins=100, density=True)
            cdf = np.cumsum(hist * np.diff(bin_edges))
            fig = go.Figure(data=[
                go.Scatter(x=bin_edges, y=cdf, name='CDF')
            ])
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

    # TODO: get the pressure around the contact point
    # calculate the force
    load_calc = np.sum(stress * 6894.76 * dx * dy)

    # if the force is the same as my input, return, if not, change the displacement by * F / calced force
    return abs((load_calc - load) / load)


if __name__ == "__main__":
    # testing the closure function with closure pressure
    from GsPy3DModel import model_3D as m3d
    import os
    import edit_polyMesh

    case_directory = 'C:/Users/tohoko.tj/dissolCases/seed2000-stdev0_05/lambda1_0-0_5-stdev0_05'

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

    deform_blockMesh(inp, df_points, roughness=None, pc=4000)


