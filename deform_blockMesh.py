import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import platform
if platform.system() == 'Windows':
    import read_field
else:
    from . import read_field

def deform_blockMesh(inp, df_points, roughness=None):  # this
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

    wids = zs[:, :, -1]- zs[:, :, 0]  # top surface - btm surface

    if close:
        lines = []
        # compute etched width before closing
        e_s = wids - lz  # lz is the original frac opening
        np.savetxt("etched_wids.csv", e_s / 0.0254, delimiter=",")
        etched_wids = e_s.reshape(-1)

        lines.append("total etched volume is: " + str(61023.7 * dx * dy * np.sum(etched_wids)) + " in3")  # 61023.7 is m3 -> in3
        # write etched_wids field file
        etched_wids = pd.DataFrame(data=etched_wids)
        read_field.write_OF_field('etched_wids', len(etched_wids), etched_wids, './')
        # 0.99 is not to completely close the touching points
        min_width = 0.99 * np.min(abs(wids), axis=1)  # search min openings along y axis at each x-coord
        wids -= np.tile(min_width, (ny+1, 1)).T # almost all time the min_width is at the edge.

        np.savetxt("wids.csv", wids / 0.0254, delimiter=",")
    else:  # shift
        zs[:, :, -1] += roughness

    for i in range(nz+1):
        zs[:, :, i] = zs[:, :, -1] - wids * ratios[i]

    xs = np.tile(x_coords, (nz+1, ny+1, 1))
    ys = np.tile(y_coords, (nz+1, nx+1, 1))
    if close:
        xs2 = xs[0, :, :]
        ys2 = ys[0, :, :]
        plt.pcolormesh(x_coords / 0.0254, y_coords / 0.0254, e_s.T / 0.0254)
        plt.xlabel('X [in]')
        plt.ylabel('Y [in]')
        cbar = plt.colorbar()
        cbar.ax.set_ylabel("Etched width [in]")
        plt.show()
        avg_w = np.mean(wids)
        lines.append('average width is {0:.5f} inch'.format(avg_w / 0.0254))
        lines.append('conductivity from cubic law is {0:.5e} md-ft'.format(avg_w * avg_w * avg_w / 12 * 1.0133e15 * 3.28084))
        plt.pcolormesh(x_coords / 0.0254, y_coords / 0.0254, wids.T / 0.0254)
        plt.xlabel('X [in]')
        plt.ylabel('Y [in]')
        cbar = plt.colorbar()
        cbar.ax.set_ylabel("0 closure stress width [in]")
        plt.show()

        open('../etched_width', "w").writelines(lines)

    xs = xs.reshape(-1)
    ys = np.transpose(ys, (0, 2, 1)).reshape(-1)
    zs = np.transpose(zs, (2, 1, 0)).reshape(-1)

    coords = np.vstack((xs, ys, zs)).T
    return pd.DataFrame(data=coords, columns=['x', 'y', 'z'])