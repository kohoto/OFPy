import os
import numpy as np
import platform
import json
from GsPy3DModel import model_3D as m3d

if platform.system() == 'Windows':
    import edit_polyMesh
    import read_field
    import matplotlib.pyplot as plt
else:
    from . import edit_polyMesh
    from . import read_field


# read nx, ny, size from the input file


def calc_cond(case_directory):
    input_file_path = case_directory + '/inp'
    inp = m3d.read_input(input_file_path)

    """ calc some parameters from inputs """
    # number of grids
    lx = inp["lx"] * 0.0254
    ly = inp["ly"] * 0.0254
    lz = inp["lz"] * 0.0254
    nx = inp["nx"]
    ny = inp["ny"]
    nz = inp["nz"]
    dx = inp["dx"]
    dens = 1.e3  # [kg/m3]
    mu = 0.001
    dy = ly / ny

    cond_dict  = {}
    for pc in range(1000, 5000, 1000):
        cond_directory = '/conductivity' + str(pc)
        print('Calculating conductivity of pc = ' + str(pc))
        df_points = edit_polyMesh.read_OF_points(case_directory + cond_directory + "/constant/polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))

        q = read_out(case_directory + cond_directory + '/q.out')
        pout = read_out(case_directory + cond_directory + '/pout.out')
        pin = read_out(case_directory + cond_directory + '/pin.out')
        dp = pin - pout

        # reshape p and U data into mesh shape
        zs = np.transpose(df_points['z'].to_numpy().reshape(nz + 1, ny + 1, nx + 1), (2, 1, 0))
        # get inlet surface area
        wids = zs[:, :, -1] - zs[:, :, 0]
        # TODO: change this calculation to function "get_wids_distribution"
        inlet_area = np.sum(wids[0, :]) * dy  # get width at inlet

        avg_w = np.mean(wids)
        min_w = 0.01 * np.min(wids)
        avg_w_nonzero = np.mean(wids[wids > min_w])


        # in OF, p is in [m2/s2]. It's devided by density!!
        dp *= dens  # TODO: need to consider further since each surf area of mesh is different.

        # compute conductivity

        cond = q[0] * mu * lx / dp / ly  # [m3]

        # Create a list of dictionaries where each dictionary represents a row
        # if cond file not exist, make it
        cond_dict['pc=' + str(pc)] = {
            'avg_w__in': avg_w / 0.0254,
            'avg_w_nonzero__in': avg_w_nonzero / 0.0254,
            'cond_cubic_avg__mdft': avg_w * avg_w * avg_w / 12 * 1.0133e15 * 3.28084,
            # conductivity from cubic law with min width
            # this is to make sure the "0 width grids" doesn't have too high conductivity
            'cond_cubic_min__mdft': min_w * min_w * min_w / 12 * 1.0133e15 * 3.28084,
            'cond__mdft': cond * 1.01325e15 * 3.28084,
            'U_in__m_s': np.average(q / inlet_area),
            'q_in__L_min': q[0] * 60000,
            'dp__psi': dp / 6895,
            'inlet_area_m2': inlet_area
        }

    filepath = case_directory + '/cond.json'
    if os.path.isfile(filepath):
        json_data = json.load(open(filepath, 'r'))

        for key, value in cond_dict.items():
            json_data[key] = value

    open(case_directory + '/cond.json', 'w').write(json.dumps(json_data, indent=4))
    return 0


def read_out(fpath):
    for line, i in zip(open(fpath), range(100)):
        if i > 39:
            a = line.split('= ')
            if a[1][0] == '(':  # vector value
                val = np.array(a[1].split('(')[1].split(')')[0].split(' '), dtype=float)
            else:  # scalar value
                val = float(a[1].split('\n')[0])
            return val


if __name__ == "__main__":
    # case_directory = '//coe-fs.engr.tamu.edu/Grads/tohoko.tj/Documents/seed7000-stdev0_15\lambda1_0-0_5-stdev0_15'
    case_directory = 'C:/Users/tohoko.tj/dissolCases/no_roughness_mineralogy/no_roughness'
    calc_cond(case_directory)
