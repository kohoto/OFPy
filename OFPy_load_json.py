import os
import json
import matplotlib.pyplot as plt
import platform
import numpy as np

if platform.system() == 'Windows':
    import plot_default_format
else:
    from . import plot_default_format
plt.style.use("my_style")

# apply default format for plots
plot_default_format.plot_format_Tohoko()
def load_json_cond(dissolCases_directory):  # For Linux and Windows (no OF command)
    initial_dir = os.getcwd()
    # store parameters
    par = {}

    # loop through each file in the directory

    case_directories = [name for name in os.listdir(dissolCases_directory) if os.path.isdir(dissolCases_directory + name)]
    print(str(len(case_directories)) + ' cases detected.')
    for case_directory in case_directories:
        filepath = dissolCases_directory + case_directory + '/cond.json'
        with open(filepath, 'r') as f:
            json_data = json.load(f)
            # loop through each key-value pair in the json data
            for key, value in json_data.items():
                if key in par:
                    par[key].append(value)  # add the value to the existing list
                else:
                    par[key] = [value]  # create a new list for the key

    key_x = 'stdev'
    key_y = 'avg_w__in'
    cubic_x = np.linspace(min(par[key_x]), max(par[key_x]), num=10)
    # plt.loglog(cubic_x, cubic_x * cubic_x * cubic_x / 12.0 * 0.0254 * 1.0133e15 * 3.28, 'r-')
    plt.loglog(par[key_x], par[key_y], 'o', label=dissolCases_directory.split("/")[-2])
    save_plot(dissolCases_directory, key_x, key_y)

    # go back to original directory
    os.chdir(initial_dir)

def save_plot(dissolCases_directory, key_x, key_y):
    plt.xlabel(key_x)
    plt.ylabel(key_y)
    plt.title(dissolCases_directory)
    plt.legend()
    # plt.show()
    splitted_case_dir_path = dissolCases_directory.split("/")
    imgpath = '/'.join(splitted_case_dir_path[:-2]) + '/' + splitted_case_dir_path[-2] + '--' + key_x + '-' + key_y + '.png'
    plt.savefig(imgpath, transparent=True)


if __name__ == "__main__":
    # dissolCases_directory = 'C:/Users/tohoko.tj/dissolCases/seed7000-stdev0_15/'
    root_directory = 'C:/Users/tohoko.tj/dissolCases/'

    dissolCases_directories = [name for name in os.listdir(root_directory) if os.path.isdir(root_directory + name)]
    print(str(len(dissolCases_directories)) + ' batch detected.')
    for dissolCases_directory in dissolCases_directories:
        print('working on ' + dissolCases_directory + '...')
        load_json_cond(root_directory + dissolCases_directory + '/')