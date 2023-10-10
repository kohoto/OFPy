import numpy as np
import pandas as pd
import plotly.graph_objects as pl
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
    lx = inp["lx"] * 0.0254
    ly = inp["ly"] * 0.0254
    lz = inp["lz"] * 0.0254
    nx = inp["nx"]  # nx is number of faces, not points
    ny = inp["ny"]
    nz = inp["nz"]

    dx = lx / nx
    dy = ly / ny
    dz = lz / nz

    xs = np.tile(np.arange(0, lx + 0.0001, dx), (ny+1, 1)).T
    ys = np.tile(np.arange(0, ly + 0.0001, dy), (nx+1, 1))

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

    # ax.plot([0, lag_dist * nlag], [1.0, 1.0], color='black')
    # ax.set_xlabel(r'Lag Distance $\bf(h)$, [in]')
    # ax.set_ylabel(r'$\gamma \bf(x)$')
    # ax.set_xlim([0, lag_dist * nlag])
    # ax.set_ylim([0, 3.0])

    # Calculate sample porosity data isotropic variogram
    # Plot variogram in vertical direction
    lag_y, gamma_y, por_npair = gsp.gamv_2d(df, "X", "Y", "Z", nlag=ny, lagdist=dy, azi=0, atol=2.0, bstand=1)

    fig = pl.Figure(data=[pl.Scatter(x=lag_x, y=gamma_x), pl.Scatter(x=lag_y, y=gamma_y)])
    fig.show()

    # Ask user to input correlation length from lag distance plot.
    hmin1 = input("Enter correlation length in y [in]:")
    hmaj1 = input("Enter correlation length in x[in]:")

    return hmaj1, hmin1, mean, stdev


def generate_variogram_lbl(x, y, width):
    # generate profilometer variogram line by line
    nx = x.shape[1]
    ny = x.shape[0]
    width = np.nan_to_num(width)

    # first investigate in x-direction
    # Calculate sample porosity data isotropic variogram
    lag_dist = 0.025  # TODO: understand these inputs
    nlag = nx
    azi = 90
    atol = 2.0
    bstand = 1
    # plot setting first
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(121)
    # plot reference line
    ax.plot([0, lag_dist * nlag], [1.0, 1.0], color='black')

    idx_x = 0
    for (x_line, y_line, width_line) in zip(x, y, width):
        idx_x += 1
        # create dataframe since GeostatsPy is based on dataframe
        sample_data = pd.DataFrame(np.array([x_line, y_line, width_line]).transpose(), columns=['X', 'Y', 'Z'])
        # Plot variogram in vertical direction
        lag, por_gamma, por_npair = gp.gamv_2d(sample_data, "X", "Y", "Z", nlag, lag_dist, azi, atol, bstand)
        ax.plot(lag, por_gamma, 'o', markersize=2, label='idx_x = ' + str(idx_x))

    # set up the graph
    ax.set_xlabel(r'Lag Distance $\bf(h)$, [in]')
    ax.set_ylabel(r'$\gamma \bf(y)$')
    ax.set_xlim([0, lag_dist * nlag])
    ax.set_ylim([0, 3.0])

    ## ==== next investigate in y-direction ====
    # In y-direction it's more tricky because the zigzag feature is in y-direction
    # Calculate sample porosity data isotropic variogram
    lag_dist = 0.025  # TODO: understand these inputs
    nlag = ny
    azi = 0
    atol = 2.0
    bstand = 1
    # plot setting first
    ax = fig.add_subplot(122)
    # plot reference line
    ax.plot([0, lag_dist * nlag], [1.0, 1.0], color='black')

    idx_y = 0
    for (x_line, y_line, width_line) in zip(x.transpose(), y.transpose(), width.transpose()):
        idx_y += 1
        for odd_idx in range(2):
            # create dataframe since GeostatsPy is based on dataframe

            sample_data = pd.DataFrame(
                np.array([x_line[odd_idx::2], y_line[odd_idx::2], width_line[odd_idx::2]]).transpose(),
                columns=['X', 'Y', 'Z'])
            # Plot variogram in vertical direction
            lag, por_gamma, por_npair = gp.gamv_2d(sample_data, "X", "Y", "Z", nlag, lag_dist, azi, atol, bstand)
            ax.plot(lag, por_gamma, 'o', markersize=2, label='idx_y = ' + str(idx_y) + '_' + str(odd_idx))

    ax.set_xlabel(r'Lag Distance $\bf(h)$, [in]')
    ax.set_ylabel(r'$\gamma \bf(y)$')
    ax.set_xlim([0, lag_dist * nlag])
    ax.set_ylim([0, 3.0])
    plt.show()

    # compute mean
    mean = width.reshape(-1).mean()
    stdev = width.reshape(-1).std()
    return mean, stdev


def ISO_filter(width):
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
    fig = plt.figure(figsize=(10, 5))
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

    inp_tuple = m3d.read_input(case_directory + input_file_path)
    inp = {"lx": inp_tuple[3], "ly": inp_tuple[4], "lz": inp_tuple[5], "dx": inp_tuple[6],
           "nx": int(inp_tuple[3] / inp_tuple[6]),
           "ny": int(inp_tuple[4] / inp_tuple[6]), "nz": inp_tuple[7], "lz": inp_tuple[8],
           "mean": inp_tuple[9], "stdev": inp_tuple[10], "hmaj1": inp_tuple[11], "hmin1": inp_tuple[12]}

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
