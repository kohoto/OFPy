import numpy as np
import json
import pandas as pd
import plotly.graph_objects as go
from GsPy3DModel import geostatspy as gsp
import OFPy_load_json
import os

def get_roughness_parameters(inp, zs):
    """
    get roughness statistical parameters of the given surface
    :param inp: inputs used in all OF and 3DModel
    :param zs: input surface
    :return: lambdax, lambday, sigma
    """

    statistic_params = {}

    statistic_params['top'] = generate_variogram(inp, zs[:, :, -1])
    statistic_params['btm'] = generate_variogram(inp, zs[:, :, 0])
    return statistic_params


def generate_variogram(inp, zs):
    from scipy.signal import find_peaks

    # read input
    lx = inp["lx"]
    ly = inp["ly"]
    nx = inp["nx"]  # nx is number of faces, not points
    ny = inp["ny"]

    dx = lx / nx
    dy = ly / ny

    xs = np.tile(np.arange(0, lx + 0.0001, dx), (ny + 1, 1)).T  # inch
    ys = np.tile(np.arange(0, ly + 0.0001, dy), (nx + 1, 1))
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
    lag_y, gamma_y, por_npair = gsp.gamv_2d(df, "X", "Y", "Z", nlag=ny, lagdist=dy, azi=0, atol=2.0, bstand=1)

    # Ask user to input correlation length from lag distance plot.
    # hmaj1 = input("Enter correlation length in x [in]:")
    # hmin1 = input("Enter correlation length in y [in]:")
    hmaj1_idx = find_peaks(gamma_x, width=0.5)[0][0]
    hmin1_idx = find_peaks(gamma_y, width=0.5)[0][0]
    varx = {"lag": lag_x, "gamma": gamma_x, "h": lag_x[hmaj1_idx]}
    vary = {"lag": lag_y, "gamma": gamma_y, "h": lag_y[hmin1_idx]}
    return {"varx": varx, "vary": vary, "mean": mean, "stdev": stdev}


def plot_variogram_all_json_in_dissolCases(root_directory):  # For Linux and Windows
    # get parameters from json file in all project directories in batch_directory
    trace_list = OFPy_load_json.apply_func_to_all_projects_in_dissolCases(root_directory, load_variogram)
    layout = go.Layout(title="Variogram",
                       xaxis_title="Lag distance [in]",
                       yaxis_title="Variogram")
    fig = go.Figure(data=trace_list, layout=layout)
    fig.add_hline(y=1)
    fig.show()

def load_variogram(dissolCases_directory, case_directory, trace_list):
    """

    """
    filepath = dissolCases_directory + '/' + case_directory + '/variogram.json'
    if os.path.isfile(filepath):
        with open(filepath, 'r') as f:
            obj = json.load(f)
            trace_list = trace_variograms(obj, trace_list, case_directory)
    return trace_list


def trace_variograms(obj, trace_list, label):
    if isinstance(obj, dict):
        if obj.get('lag') == None: # while I can't find lag and gamma, keep looping
            for key, value in obj.items():
                if isinstance(value, dict):
                    trace_list = trace_variograms(value, trace_list, label + "_" + key)
                else:
                    continue

        else:
            l = trace_variogram(obj, label)
            trace_list.extend(l)

    return trace_list


def trace_variogram(var_dict, label):
    idx = var_dict["lag"].index(var_dict["h"])
    return [go.Scatter(x=var_dict["lag"], y=var_dict["gamma"], name=label),
            go.Scatter(x=[var_dict["h"]], y=[var_dict["gamma"][idx]], mode='markers', showlegend=False)]


def generate_variogram_lbl(inp, zs):
    # generate profilometer variogram line by line
    # read input
    lx = inp["lx"]
    ly = inp["ly"]
    nx = inp["nx"]  # nx is number of faces, not points
    ny = inp["ny"]

    dx = lx / nx
    dy = ly / ny

    xs = np.tile(np.arange(0, lx + 0.0001, dx), (ny + 1, 1)).T  # inch
    ys = np.tile(np.arange(0, ly + 0.0001, dy), (nx + 1, 1))
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
    root_dir = 'C:/Users/tohoko.tj/dissolCases/'
    trace = plot_variogram_all_json_in_dissolCases(root_dir)

