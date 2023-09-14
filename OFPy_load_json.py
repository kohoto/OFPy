import os
import json
import matplotlib.pyplot as plt
import platform
import numpy as np
import pandas as pd

if platform.system() == 'Windows':
    import plot_default_format
else:
    from . import plot_default_format
plt.style.use("my_style")

# apply default format for plots
plot_default_format.plot_format_Tohoko()
def load_json_cond(root_directory):  # For Linux and Windows (no OF command)
    """

    """
    initial_dir = os.getcwd()
    # store parameters
    par = {}

    # loop through each file in the directory
    # correct folder names (not path)
    dissolCases_directories = [name for name in os.listdir(root_directory) if os.path.isdir(root_directory + name)]
    print(str(len(dissolCases_directories)) + ' batch detected.')

    # seed and stdev fixed
    dissolCases_directories = [root_directory + s for s in dissolCases_directories]
    for dissolCases_directory in dissolCases_directories:
        print('working on ' + dissolCases_directory + '...')
        case_directories = [name for name in os.listdir(dissolCases_directory) if os.path.isdir(dissolCases_directory + '/' + name)]
        print(str(len(case_directories)) + ' cases detected.')

        # lambdas changed for each case directory
        for case_directory in case_directories:
            filepath = dissolCases_directory + '/' + case_directory + '/cond.json'
            with open(filepath, 'r') as f:
                json_data = json.load(f)
                # loop through each key-value pair in the json data
                for key, value in json_data.items():
                    if key in par:
                        par[key].append(value)  # add the value to the existing list
                    else:
                        par[key] = [value]  # create a new list for the key

    # convert to pandas
    par = pd.DataFrame.from_dict(par)

    # choose the formatting rules for the plots
    # key_x = 'avg_w__in'; key_y = 'cond__mdft'; key_c = 'lambda_x__in'; key_m = 'stdev'
    # key_x = 'stdev'; key_y = 'avg_w__in'; key_c = 'lambda_x__in'; key_m = 'lambda_x__in'
    key_x = 'lambda_x__in'; key_y = 'avg_w__in'; key_c = 'stdev'; key_m = 'stdev'

    iter = 0
    marker = ['o', '^', 's', 'v']
    fig, ax = plt.subplots()
    grouped = par.groupby(key_m) # m for marker

    for val_m in par[key_m].unique():
        group = grouped.get_group(val_m)
        im = ax.scatter(group[key_x], group[key_y], s=val_m * 1000, c=group[key_c], cmap='Greens', edgecolors='k')

    save_plot(root_directory, ax, key_x, key_y, key_c, im)

    # go back to original directory
    os.chdir(initial_dir)

def update_json():
    """
    Update the content of cond.json
    :return:
    """
def save_plot(root_directory, ax, key_x, key_y, key_c, im):
    cbar = plt.colorbar(im)
    cbar.set_label(key_c, rotation=270)
    #ax.set_xlim([0.001, 0.1])
    #ax.set_ylim([1, 1e6])
    ax.set_xlabel(key_x)
    ax.set_ylabel(key_y)
    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_title(root_directory)
    imgpath = root_directory + key_x + '-' + key_y + '.png'
    #plt.show()
    plt.savefig(imgpath, transparent=True)


if __name__ == "__main__":
    # dissolCases_directory = 'C:/Users/tohoko.tj/dissolCases/seed7000-stdev0_15/'
    root_directory = 'C:/Users/tohoko.tj/dissolCases/'

    load_json_cond(root_directory)