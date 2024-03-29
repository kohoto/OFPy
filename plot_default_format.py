import platform
if platform.system() == 'Windows':
    import matplotlib.pyplot as plt

def plot_format_Tohoko():
    """
    Set the plot format for my TAMU PowerPoint presentations
    :return: none
    """
    plt.rcParams['font.family'] = 'Segoe UI'
    plt.rcParams['axes.grid'] = True
    plt.rcParams['xtick.direction'] = 'in'  # x axis in
    plt.rcParams['ytick.direction'] = 'in'  # y axis in
    plt.rcParams['axes.linewidth'] = 1.0  # axis line width
    plt.rcParams["font.size"] = 12