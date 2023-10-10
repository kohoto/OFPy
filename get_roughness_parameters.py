import numpy as np
import pandas as pd
import plotly.graph_objects as go
from GsPy3DModel import geostatspy as gsp
from GsPy3DModel import model_3D as m3d
import edit_polyMesh
import os

def get_roughness_parameters(inp, zs):
    """
    get roughness statistical parameters of the given surface
    :param inp: inputs used in all OF and 3DModel
    :param zs: input surface
    :return: lambdax, lambday, sigma
    """

    statistic_params = {}

    [statistic_params['lambdax_top'],
     statistic_params['lambdaz_top'],
     statistic_params['mean_top'],
     statistic_params['sigma_top']] = generate_variogram(inp, zs[:, :, -1])
    [statistic_params['lambdax_btm'],
     statistic_params['lambdaz_btm'],
     statistic_params['mean_btm'],
     statistic_params['sigma_btm']] = generate_variogram(inp, zs[:, :, 0])

    return statistic_params


def generate_variogram(inp, zs):

    # read input
    lx = inp["lx"]
    ly = inp["ly"]
    nx = inp["nx"]  # nx is number of faces, not points
    ny = inp["ny"]

    dx = lx / nx
    dy = ly / ny

    xs = np.tile(np.arange(0, lx + 0.0001, dx), (ny+1, 1)).T  # inch
    ys = np.tile(np.arange(0, ly + 0.0001, dy), (nx+1, 1))
    zs = zs / 0.0254

    # compute mean and stdev
    mean = np.nanmean(zs.reshape(-1))
    stdev = np.nanstd(zs.reshape(-1))

    print('mean: ' + str(mean) + '\nstdev: ' + str(stdev))

    # create dataframe since GeostatsPy is based on dataframe
    zs = np.nan_to_num(zs)
    df = pd.DataFrame(np.array([xs.reshape(-1), ys.reshape(-1), zs.reshape(-1)]).transpose(),
                      columns=['X', 'Y', 'Z'])

    # Plot variogram in horizontal direction
    lag_x, gamma_x, por_npair = gsp.gamv_2d(df, "X", "Y", "Z", nlag=nx, lagdist=dx, azi=90, atol=2.0, bstand=1)

    # Plot variogram in vertical direction
    lag_y, gamma_y, por_npair = gsp.gamv_2d(df, "X", "Y", "Z", nlag=ny, lagdist=dy, azi=0, atol=2.0, bstand=1)
    layout = go.Layout(title="Variogram",
                       xaxis_title="Lag distance [in]",
                       yaxis_title="Variogram")
    fig = go.Figure(data=[go.Scatter(x=lag_x, y=gamma_x, name="x-dir"),
                          go.Scatter(x=lag_y, y=gamma_y, name="y-dir")],
                    layout=layout)
    fig.add_hline(y=1)
    fig.show()

    # Ask user to input correlation length from lag distance plot.
    hmaj1 = input("Enter correlation length in x [in]:")
    hmin1 = input("Enter correlation length in y [in]:")

    return hmaj1, hmin1, mean, stdev


def generate_variogram_lbl(inp, zs):
    # generate profilometer variogram line by line
    # read input
    lx = inp["lx"]
    ly = inp["ly"]
    nx = inp["nx"]  # nx is number of faces, not points
    ny = inp["ny"]

    dx = lx / nx
    dy = ly / ny

    xs = np.tile(np.arange(0, lx + 0.0001, dx), (ny+1, 1)).T  # inch
    ys = np.tile(np.arange(0, ly + 0.0001, dy), (nx+1, 1))
    zs = zs / 0.0254

    # compute mean and stdev
    mean = np.nanmean(zs.reshape(-1))
    stdev = np.nanstd(zs.reshape(-1))

    print('mean: ' + str(mean) + '\nstdev: ' + str(stdev))

    # create dataframe since GeostatsPy is based on dataframe
    zs = np.nan_to_num(zs)

    # Plot variogram in horizontal direction
    traces = []
    idx_x = 0
    for (x_line, y_line, width_line) in zip(xs, ys, zs):
        idx_x += 1
        # create dataframe since GeostatsPy is based on dataframe
        df = pd.DataFrame(np.array([x_line, y_line, width_line]).transpose(), columns=['X', 'Y', 'Z'])
        lag_x, gamma_x, por_npair = gsp.gamv_2d(df, "X", "Y", "Z", nlag=nx, lagdist=dx, azi=90, atol=2.0, bstand=1)
        traces.append(go.Scatter(x=lag_x, y=gamma_x, name="x-dir" + str(idx_x)))

    # Plot variogram in vertical direction
    idx_y = 0
    for (x_line, y_line, width_line) in zip(xs.transpose(), ys.transpose(), zs.transpose()):
        idx_y += 1
        for odd_idx in range(2):
            # create dataframe since GeostatsPy is based on dataframe
            df = pd.DataFrame(
                np.array([x_line[odd_idx::2], y_line[odd_idx::2], width_line[odd_idx::2]]).transpose(),
                columns=['X', 'Y', 'Z'])
            # Plot variogram in vertical direction
            lag_y, gamma_y, por_npair = gsp.gamv_2d(df, "X", "Y", "Z", nlag=ny, lagdist=dy, azi=0, atol=2.0, bstand=1)
            traces.append(go.Scatter(x=lag_y, y=gamma_y, name="y-dir" + str(idx_y)))

    layout = go.Layout(title="Variogram",
                       xaxis_title="Lag distance [in]",
                       yaxis_title="Variogram")
    fig = go.Figure(data=traces, layout=layout)
    fig.add_hline(y=1)
    fig.show()

    # Ask user to input correlation length from lag distance plot.
    hmaj1 = input("Enter correlation length in x [in]:")
    hmin1 = input("Enter correlation length in y [in]:")

    return hmaj1, hmin1, mean, stdev


def iso_filter(width):
    waviness = np.zeros(width.shape)
    for w, iy in zip(width, range(width.shape[0])):  # loop for each row
        for iter in range(100):
            avg_3pt = np.nanmean(np.vstack((w[:-2], w[1:-1], w[2:])), axis=0)
            avg_3pt = np.insert(avg_3pt, [0], w[0])
            avg_3pt = np.insert(avg_3pt, [-1], w[-1])
            w = avg_3pt
        waviness[iy, :] = w

    roughness = width - waviness
    return waviness, roughness


def plot_waviness_and_roughness(waviness, roughness, width):
    fig = go.Figure()
    y_mid = int(waviness.shape[0] / 2)
    # plot original
    ax = fig.add_subplot(311)
    ax.plot(width[y_mid, :])
    ax.set_xlabel(r'X')
    ax.set_ylabel(r'original')

    # plot waviness
    ax = fig.add_subplot(312)
    ax.plot(waviness[y_mid, :])
    ax.set_xlabel(r'X')
    ax.set_ylabel(r'waviness')

    # plot roughenss
    ax = fig.add_subplot(313)
    ax.plot(roughness[y_mid, :])
    ax.set_xlabel(r'X')
    ax.set_ylabel(r'roughness')


if __name__ == '__main__':  # testing the function

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
    zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))

    statistic_params_top = get_roughness_parameters(inp, zs)
