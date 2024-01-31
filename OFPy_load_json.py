import os
import json
import platform
import numpy as np
import pandas as pd
from GsPy3DModel import model_3D as m3d
import edit_polyMesh
import get_roughness_parameters
import numpy as np
import scipy as sp
import pandas as pd
import platform
import math as m

if platform.system() == 'Windows':
    from plotly.subplots import make_subplots
    import matplotlib.pyplot as plt
    import plotly.graph_objects as go
    import plot_default_format
    import plotly.express as px
else:
    from . import plot_default_format

# apply default format for plots
plot_default_format.plot_format_Tohoko()


def write_variogram_all_json_in_dissolCases(root_directory):  # For Linux and Windows
    # get parameters from json file in all project directories in batch_directory
    apply_func_to_all_projects_in_dissolCases(root_directory, write_variogram_json)


def rewrite_all_json_in_dissolCases(root_directory):  # For Linux and Windows
    # get parameters from json file in all project directories in batch_directory
    apply_func_to_all_projects_in_dissolCases(root_directory, rewrite_json)


def update_all_json_in_dissolCases(root_directory):  # For Linux and Windows
    # get parameters from json file in all project directories in batch_directory
    trace = apply_func_to_all_projects_in_dissolCases(root_directory, update_json)
    layout = go.Layout(title="Variogram",
                       xaxis_title="Lag distance [in]",
                       yaxis_title="Variogram")
    fig = go.Figure(data=trace, layout=layout)
    fig.add_hline(y=1)
    fig.show()


def concatenate_all_json_in_dissolCases(root_directory):
    par = apply_func_to_all_projects_in_dissolCases(root_directory, concatenate_json)
    open(root_directory + '/combined.json', 'w').write(json.dumps(par, indent=4))


def replace_all_json_in_dissolCases(root_directory):
    apply_func_to_all_projects_in_dissolCases(root_directory, replace_infinity_json)

def tabulate_cond_data(root_directory):
    par = apply_func_to_all_projects_in_dissolCases(root_directory, read_cond_data)


def read_cond_data(dissolCases_directory, case_directory, par):  # For Linux and Windows (no OF command)
    """
    Replace infinity to numbers in all json files so that Excel can read it
    :param dissolCases_directory: path of the dissolCases directory
    :param case_directory: name of the case directory
    :return: list of concatenated dictionaries. At the end of the iteration it should be dumped to json.
    """
    from tabulate import tabulate
    dirpath = dissolCases_directory + '/' + case_directory
    filepath = dirpath + '/cond.json'

    if os.path.isfile(filepath):
        json_data = json.load(open(filepath, 'r'))
        par = {}
        par['pc'] = [0, 1000, 2000, 3000, 4000]
        for pc in par['pc']:
            for key, value in json_data['pc=' + pc].items():
                if key in par:
                    par[key].append(value)  # add the value to the existing list
                else:
                    par[key] = [value]  # create a new list for the key
    else:
        print('ignored: ' + filepath)

    # write table file
    open('cond.txt', 'w').write(tabulate(par))
    return {}

def tabulate_inp_data(root_directory):  # For Linux and Windows
    # get parameters from json file in all project directories in batch_directory
    par = apply_func_to_all_projects_in_dissolCases(root_directory, load_json_cond)
    # this
    # convert to pandas
    df = pd.DataFrame.from_dict(par)
    x = 'lambda_x__in'
    y = 'cond__mdft'
    if par['pc=0'].get(x) != None or par['pc=0'].get(y) != None:
        pd.concat([df, df2[df2['pc'] == 0]], axis=1)

        color_by = 'stdev'

    if platform.system() == 'Windows':
        # show the contour of fracture opening
        # np.where... is not to show the closed points in plot
        fig = px.scatter(df, x=x, y=y, color=color_by)
        fig.show()


def plot_trend(root_directory):  # For Linux and Windows
    # get parameters from json file in all project directories in batch_directory
    par = apply_func_to_all_projects_in_dissolCases(root_directory, load_json_cond)

    # convert to pandas
    par = pd.DataFrame.from_dict(par)
    # choose the formatting rules for the plots
    # key_x = 'avg_w__in'; key_y = 'cond__mdft'; key_c = 'lambda_x__in'; key_m = 'stdev'
    # key_x = 'stdev'; key_y = 'avg_w__in'; key_c = 'lambda_x__in'; key_m = 'lambda_x__in'
    key_x = 'avg_w__in';
    key_y = 'cond__mdft';
    key_c = 'seed';
    key_m = 'stdev'

    iter = 0
    marker = ['o', '^', 's', 'v']
    fig, ax = plt.subplots()
    grouped = par.groupby(key_m)  # m for marker

    for val_m in par[key_m].unique():
        group = grouped.get_group(val_m)
        im = ax.scatter(group[key_x], group[key_y], s=val_m * 1000, c=group[key_c], cmap='Greens', edgecolors='k')

    save_plot(root_directory, ax, key_x, key_y, key_c, im)


## dependent functions
def apply_func_to_all_projects_in_dissolCases(root_directory, func):
    """

    """
    initial_dir = os.getcwd()
    out = {}

    # loop through each file in the directory
    # correct folder names (not path)
    dissolCases_directories = [name for name in os.listdir(root_directory) if os.path.isdir(root_directory + name)]
    print(str(len(dissolCases_directories)) + ' batch detected.')

    # seed and stdev fixed
    dissolCases_directories = [root_directory + s for s in dissolCases_directories]
    for dissolCases_directory in dissolCases_directories:
        print('working on ' + dissolCases_directory + '...')
        case_directories = [name for name in os.listdir(dissolCases_directory) if
                            os.path.isdir(dissolCases_directory + '/' + name)]
        print(str(len(case_directories)) + ' cases detected.')

        # lambdas changed for each case directorout = {dict: 21} {'lambda1_0-0_5-stdev0_025': {'lambda_x__in': 1.0, 'lambda_z__in': 0.5, 'stdev': 0.025, 'avg_w__in': 0.004957572673928679, 'cond_cubic_avg__mdft': 553.1593602340021, 'cond_cubic_max__mdft': 2309.78856759821, 'cond__mdft': 391.2439876930291, 'U_in__m_s': 1.... Viewy
        for case_directory in case_directories:
            out = func(dissolCases_directory, case_directory, out)

    # go back to original directory
    os.chdir(initial_dir)
    return out


def load_json_cond(dissolCases_directory, case_directory, par):  # For Linux and Windows (no OF command)
    """
    Concatenate all json files in
    :param dissolCases_directory: path of the dissolCases directory
    :param case_directory: name of the case directory
    :param combined_pars: list of dictionaries that contain parameters for each case
    :return: list of concatenated dictionaries. At the end of the iteration it should be dumped to json.
    """
    filepath = dissolCases_directory + '/' + case_directory + '/cond.json'
    if os.path.isfile(filepath):
        with open(filepath, 'r') as f:
            json_data = json.load(f)
            # loop through each key-value pair in the json data
            for key, value in json_data.items():
                if key in par:
                    par[key].append(value)  # add the value to the existing list
                else:
                    par[key] = [value]  # create a new list for the key
    else:
        print('ignored: ' + filepath)

    return par


def update_json(dissolCases_directory, case_directory, trace):  # For Linux and Windows (no OF command)
    """
    Update the content of cond.json from the old format to the new format. (The file geenrated before 9/14/2023 is in old format.)
    :return:
    """
    filepath = dissolCases_directory + '/' + case_directory + '/cond.json'
    if os.path.isfile(filepath):
        json_data = json.load(open(filepath, 'r'))
        input_file_path = dissolCases_directory + '/' + case_directory + '/inp'
        inp = m3d.read_input(input_file_path)
        print('Working on ' + dissolCases_directory + '/' + case_directory)
        if "seed" not in json_data:
            # read seed from inp
            json_data["seed"] = inp["seed"]

        if "top" not in json_data:
            # calc some parameters from data in inp
            nx = inp["nx"]
            ny = inp["ny"]
            nz = inp["nz"]

            os.chdir(dissolCases_directory + '/' + case_directory + "/etching")
            last_timestep_dir = str(max([int(a) for a in os.listdir('../etching') if a.isnumeric()]))

            df_points = edit_polyMesh.read_OF_points(last_timestep_dir + "/polyMesh/points",
                                                     nrows=(nx + 1) * (ny + 1) * (nz + 1))
            zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
            statistic_params = get_roughness_parameters.get_roughness_parameters(inp, zs)
            json_data.update(statistic_params)

            #
            df_points = edit_polyMesh.read_OF_points("0/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
            zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
            statistic_params_before = get_roughness_parameters.get_roughness_parameters(inp, zs)

        # Open the JSON file for writing (this will overwrite the existing file)
        open(filepath, 'w').write(json.dumps(json_data, indent=4))
    else:
        print('ignored: ' + filepath)

    return trace  # return empty dict for consistency


def rewrite_json(dissolCases_directory, case_directory, trace):  # For Linux and Windows (no OF command)
    """
    Update the content of cond.json from the old format to the new format. (The file geenrated before 9/14/2023 is in old format.)
    :return:
    """
    filepath = dissolCases_directory + '/' + case_directory + '/cond.json'
    if os.path.isfile(filepath):
        json_data = json.load(open(filepath, 'r'))
        input_file_path = dissolCases_directory + '/' + case_directory + '/inp'
        inp = m3d.read_input(input_file_path)
        print('Working on ' + dissolCases_directory + '/' + case_directory)

        if "top" in json_data:
            open(filepath, 'w').write(json.dumps(json_data))
    else:
        print('ignored: ' + filepath)

    return trace  # return empty dict for consistency


def write_variogram_json(dissolCases_directory, case_directory, par):  # For Linux and Windows (no OF command)
    """
    Update the content of cond.json from the old format to the new format. (The file geenrated before 9/14/2023 is in old format.)
    :return:
    """
    casepath = dissolCases_directory + '/' + case_directory
    filepath = casepath + '/variogram.json'
    if not os.path.isfile(filepath): # work on this only when file is not exist.
        input_file_path = casepath + '/inp'
        if os.path.isfile(input_file_path):
            inp = m3d.read_input(input_file_path)
            print('Working on ' + dissolCases_directory + '/' + case_directory)

            # calc some parameters from data in inp
            nx = inp["nx"]
            ny = inp["ny"]
            nz = inp["nz"]

            etching_dir = casepath + "/etching"
            if os.path.isdir(etching_dir):
                os.chdir(etching_dir)
                last_timestep_dir = str(max([int(a) for a in os.listdir('../etching') if a.isnumeric()]))

                statistic_params = {}
                df_points = edit_polyMesh.read_OF_points(last_timestep_dir + "/polyMesh/points",
                                                         nrows=(nx + 1) * (ny + 1) * (nz + 1))
                zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
                statistic_params['after'] = get_roughness_parameters.get_roughness_parameters(inp, zs)

                df_points = edit_polyMesh.read_OF_points("0/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
                zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
                statistic_params['before'] = get_roughness_parameters.get_roughness_parameters(inp, zs)

                # Open the JSON file for writing (this will overwrite the existing file)
                open(filepath, 'w').write(json.dumps(statistic_params, indent=4))
            else:
                print('No etching: ' + casepath)
        else:
            print('No inp: ' + casepath)
    return {}  # return empty dict for consistency


def concatenate_json(dissolCases_directory, case_directory, combined_pars):  # For Linux and Windows (no OF command)
    """
    Concatenate all json files in
    :param dissolCases_directory: path of the dissolCases directory
    :param case_directory: name of the case directory
    :param combined_pars: list of dictionaries that contain parameters for each case
    :return: list of concatenated dictionaries. At the end of the iteration it should be dumped to json.
    """
    dirpath = dissolCases_directory + '/' + case_directory
    filepath = dirpath + '/cond.json'
    if os.path.isfile(filepath):
        with open(filepath, 'r') as f:
            combined_pars[dirpath] = json.load(f)
    else:
        print('ignored: ' + filepath)

    return combined_pars


def replace_infinity_json(dissolCases_directory, case_directory, par):  # For Linux and Windows (no OF command)
    """
    Replace infinity to numbers in all json files so that Excel can read it
    :param dissolCases_directory: path of the dissolCases directory
    :param case_directory: name of the case directory
    :return: list of concatenated dictionaries. At the end of the iteration it should be dumped to json.
    """
    dirpath = dissolCases_directory + '/' + case_directory
    filepath = dirpath + '/cond.json'

    if os.path.isfile(filepath):
        json_data = json.load(open(filepath, 'r'))
        json_data = replace_infinity(json_data)
        open(filepath, 'w').write(json.dumps(json_data, indent=4))
    else:
        print('ignored: ' + filepath)

    return {}


def replace_infinity(obj):
    if isinstance(obj, dict):
        for key, value in obj.items():
            obj[key] = replace_infinity(value)
    elif isinstance(obj, list):
        for i in range(len(obj)):
            obj[i] = replace_infinity(obj[i])
    elif isinstance(obj, float):
        if obj == float('inf'):
            return '#N/A'

    return obj


def save_plot(root_directory, ax, key_x, key_y, key_c, im):
    cbar = plt.colorbar(im)
    cbar.set_label(key_c, rotation=270)
    ax.set_xlim([0.001, 0.1])
    ax.set_ylim([10, 1e4])
    ax.set_xlabel(key_x)
    ax.set_ylabel(key_y)
    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_title(root_directory)
    imgpath = root_directory + key_x + '-' + key_y + '.png'
    plt.show()
    # plt.savefig(imgpath, transparent=True)


if __name__ == "__main__":
    # batch_directory = 'C:/Users/tohoko.tj/dissolCases/seed7000-stdev0_15/'
    # root_dir = 'C:/Users/tohoko.tj/dissolCases/'
    root_dir = 'R:/PETE/Hill_Dan/Students/Tajima_Tohoko/dissolCases2/stdev0_075/'
    # root_dir = 'C:/Users/tohoko.tj/OneDrive - Texas A&M University/Documents/20_Reseach/Simulation/OpenFOAM_results/dissolCases3/stdev0_1/'
    write_variogram_all_json_in_dissolCases(root_dir)
    # rewrite_all_json_in_dissolCases(root_dir)
    # update_all_json_in_dissolCases(root_dir)
    # tabulate_inp_data(root_dir)
    # replace_all_json_in_dissolCases(root_dir)
    # concatenate_all_json_in_dissolCases(root_dir)
    # plot_trend(root_dir)
