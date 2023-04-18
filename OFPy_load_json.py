import os
import json
import matplotlib.pyplot as plt
import platform

if platform.system() == 'Windows':
    import plot_default_format
else:
    from . import plot_default_format

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

    key_x = 'avg_w__in'
    key_y = 'cond_cubic_avg__mdft'
    plt.loglog(par[key_x], par[key_y],'o')
    plt.xlabel(key_x)
    plt.ylabel(key_y)
    plt.show()
    os.chdir(initial_dir)

if __name__ == "__main__":
    dissolCases_directory = 'C:/Users/tohoko.tj/dissolCases/seed7000-stdev0_15/'
    load_json_cond(dissolCases_directory)