import numpy as np
import pandas as pd

pd.options.mode.chained_assignment = None  # default='warn'
from scipy.interpolate import interp2d
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.ticker import LinearLocator


def read_OF_points(fpath, nrows):
    df = pd.read_csv(fpath, skiprows=20, nrows=nrows, sep=" ", header=None, names=["x", "y", "z"])
    # df.drop(df.tail(2).index, inplace=True)  # drop last 2 rows

    df["x"] = df["x"].astype(str).str.replace("(", '').astype(float)
    df["y"] = df["y"].astype(float)
    df["z"] = df["z"].astype(str).str.replace(")", '').astype(float)

    # extract the points only from surface (this affects only for points_surface)
    # df.drop(df[df["z"] > 0.1].index, inplace=True)
    df = df.drop_duplicates().reset_index(drop=True)
    return df


def read_OF_faces(fpath, nrows):
    df = pd.read_csv(fpath, skiprows=20, nrows=nrows, sep=" ", header=None, index_col=None,
                     names=["np_p1", "p2", "p3", "p4"])

    df[["np", "p1"]] = df["np_p1"].str.split("(", expand=True)
    df["np"] = df["np"].astype(int)
    df["p1"] = df["p1"].astype(int)
    df["p2"] = df["p2"].astype(int)
    df["p3"] = df["p3"].astype(int)
    df["p4"] = df["p4"].astype(str).str.replace(")", '').astype(int)
    df = df.drop("np_p1", axis='columns')
    df = df.iloc[:, [3, 4, 0, 1, 2]]

    return df


def read_OF_cells(fpath, nrows):
    df = pd.read_csv(fpath, skiprows=21, nrows=nrows, sep=" ", header=None, names=["cell"])
    df["cell"] = df["cell"].astype(int)
    return df


def get_OF_headers(cls, object, ndata, note=""):
    h0 = ["/*--------------------------------*- C++ -*----------------------------------*\n",
               "| =========                 |                                                 |\n",
               "| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |\n",
               "|  \\    /   O peration     | Version:  v1912                                 |\n",
               "|   \\  /    A nd           | Website:  www.openfoam.com                      |\n",
               "|    \\/     M anipulation  |                                                 |\n",
               "\*---------------------------------------------------------------------------*/\n",
               "FoamFile\n",
               "{\n",
               "    version     2.0;\n",
               "    format      ascii;\n",
               "    class       {};\n".format(cls)]
    h1 = ['    note        "{}";\n'.format(note)]
    h2 = ['    location    "constant/polyMesh";\n',
               "    object      {};\n".format(object),
               "}\n",
               "// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //\n\n\n",
               "{}\n".format(str(ndata)),
               "(\n"]

    if note != "":
        headers = h0 + h1 + h2
    else:
        headers = h0 + h2

    return headers

def get_OF_pathces(patch_name, n_faces, start_face):
    patch = ["    {}\n".format(patch_name),
            "    {\n",
            "        type            patch;\n",
            "        nFaces          {};\n".format(n_faces),
            "        startFace       {};\n".format(start_face),
            "    }\n"]

    return patch
# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    ly = 1.60 * 0.0254
    lx = 7.0 * 0.0254
    ny = 68
    nx = 280
    nz = 4
    prev_width_array = np.empty((nx+1, ny+1))



    df_all = read_OF_points("polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_all['index_column'] = df_all.index
    df = read_OF_points("polyMesh/points_surface", nrows=(nx + 1) * (ny + 1))
    df_mi = read_OF_points("polyMesh/points_surface_mirrored", nrows=(nx + 1) * (ny + 1))
    df_faces = read_OF_faces("polyMesh/faces", nrows=nx * nz * (ny + 1) + nx * ny * (nz + 1) + ny * nz * (nx + 1))
    df_owner = read_OF_cells("polyMesh/owner", nrows=nx * nz * (ny + 1) + nx * ny * (nz + 1) + ny * nz * (nx + 1))
    df_neighbour = read_OF_cells("polyMesh/neighbour",
                                 nrows=nx * nz * (ny - 1) + nx * ny * (nz - 1) + ny * nz * (nx - 1))

    # plot closed fracture
    fig, ax = plt.subplots(subplot_kw={"projection": "3d"})
    ax.scatter(df['x'], df['y'], df['z'], '.')
    ax.set_xlabel('X Label')
    ax.set_ylabel('Y Label')
    ax.set_zlabel('Z Label')
    ax.set_box_aspect((np.ptp(df['x'].to_numpy()), np.ptp(df['y'].to_numpy()), np.ptp(df['z'].to_numpy()) * 100))
    plt.show()

    dy = ly / ny
    dx = lx / nx
    y_coords = np.arange(0, ly + 0.0001, dy)
    interval = 0.4534
    for x, ix in zip(np.arange(0, lx + 0.0001, dx), range(nx + 1)):
        df_col = df[(df['x'] <= x + interval * dx) & (df['x'] > x - interval * dx)]  # find a row to close
        df_col = df_col.sort_values(by=['y'])  # change to ascending order

        # do the same for mirrored
        df_col_mi = df_mi[(df_mi['x'] <= x + interval * dx) & (df_mi['x'] > x - interval * dx)]  # find a row to close
        df_col_mi = df_col_mi.sort_values(by=['y'])  # change to ascending order


        prev_width = df_col_mi.loc[:, 'z'].to_numpy() - df_col.loc[:, 'z'].to_numpy()

        prev_width_array[ix, :] = prev_width

        min_width = prev_width.min() * 0.99
        for i in df_col.index:
            df_col.loc[i, 'z'] += min_width  # move up the bottom plate

        if x == 0.0:
            df_new = df_col
        else:
            df_new = pd.concat([df_new, df_col])

        # do the same things for the internal
        df_all_col = df_all[ix::nx + 1]  # find a row to close

        if len(df_all_col) != 345:
            print('col size is not good!!')

        df_all_col = df_all_col.reset_index(drop=True)

        # ratio = new_width / old_width
        ratios = (df_col_mi.loc[:, 'z'].to_numpy() - df_col.loc[:, 'z'].to_numpy()) / prev_width
        ratios = np.nan_to_num(ratios, nan=1)

        # TODO: since the solubleWall doesn't include last points in y-dir, we don't have enough points for surface. That's why I added one more point.

        for y, iy in zip(y_coords, range(y_coords.shape[0])):
            # df_all_col_row = df_all_col[(df_all_col['y'] <= y + 0.5 * dy) & (df_all_col['y'] > y - 0.5 * dy)]
            df_all_col_row = df_all_col[iy::ny + 1]
            # if iy < 4 and ix < 4:
            #     print(df_all_col_row)

            if len(df_all_col_row) != 5:
                print('col_row size is not good!!')
            # df_all_col_row = df_all_col_row.reset_index(drop=True)
            for i in df_all_col_row.index:
                df_all_col_row.loc[i, 'z'] = (df_all_col_row.loc[i, 'z'] - df_all_col_row.loc[:, 'z'].max()) * ratios[iy] + df_all_col_row.loc[:, 'z'].max()

            # TODO: find the 0 width points
            if ratios[iy] < 1e-7:
                if "same_points_list" not in locals():
                    same_points_list = [df_all_col_row.loc[:, 'index_column']]
                else:
                    # store 0 points indicis
                    same_points_list = np.append(same_points_list, [df_all_col_row.loc[:, 'index_column']], axis=0)

            # print(df_all_col_row)
            df_all_col_row['x'] = x
            df_all_col_row['y'] = y

            if x == 0.0 and y == 0.0:
                df_all_new = df_all_col_row
            else:
                df_all_new = pd.concat([df_all_new, df_all_col_row])

            # temporaly store for plot
            if y == 0.0:
                df_temp = df_all_col_row
            else:
                df_temp = pd.concat([df_temp, df_all_col_row])

    # plot closed fracture
    plt.pcolormesh(prev_width_array)
    plt.show()

    # edit points (remove the same points, store new & old index)
    # TODO: make the index the same for four points. (use the same index as the rough surface)
    df_all_new.index = df_all_new['index_column']
    if 'same_points_list' in locals():
        for same_points in same_points_list:
            for same_point in same_points[1:]:
                df_all_new.drop(same_point, inplace=True)

    df_all_new.sort_index(inplace=True)  # why
    df_all_new.reset_index(drop=True, inplace=True)
    # edit faces (change the rectangle to triangle if two same points are found. )
    # change the index to the first point
    if 'same_points_list' in locals():
        for same_points in same_points_list:
            # print(same_points[0])
            for same_point in same_points[1:]:
                df_faces['p1'].mask(df_faces['p1'] == same_point, same_points[0], inplace=True) # I think this code doesn't work because other points (points that didn't have duplicates) don't change the value.
                # actually they also change the value, because as the duplicated points are deleted, index will be shifted.
                df_faces['p2'].mask(df_faces['p2'] == same_point, same_points[0], inplace=True)
                df_faces['p3'].mask(df_faces['p3'] == same_point, same_points[0], inplace=True)
                df_faces['p4'].mask(df_faces['p4'] == same_point, same_points[0], inplace=True)

    face_to_be_deleted = []
    for i, faces in df_faces.iterrows():
        new_list = list(dict.fromkeys(faces[1:]))  # remove duplicates
        new_list.insert(0, faces[0])
        if len(new_list) == 4:
            new_list = np.append(new_list, float('nan'))
            new_list[0] = 3
        if len(new_list) == 3:
            face_to_be_deleted.append(i)
            new_list = np.append(new_list, float('nan'))
            new_list = np.append(new_list, float('nan'))
            new_list[0] = 2

            # find this face

        df_faces.loc[i, :] = new_list

    # modify the indeces to the new indeces
    # TODO: some of the big numbers are not changed here
    for old_idx, new_idx in zip(df_all_new['index_column'], df_all_new.index):
        df_faces = df_faces.replace([old_idx], new_idx)

    # plot closed fracture
    # fig, ax = plt.subplots(subplot_kw={"projection": "3d"})
    # ax.scatter(df_new['x'], df_new['y'], df_new['z'], '.')
    # ax.set_xlabel('X Label')
    # ax.set_ylabel('Y Label')
    # ax.set_zlabel('Z Label')
    # ax.set_box_aspect((np.ptp(df['x'].to_numpy()), np.ptp(df['y'].to_numpy()), np.ptp(df['z'].to_numpy()) * 100))
    # plt.show()

    # write output file

    footers = [")\n\n",
               "// ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** * //"]


    with open("polyMesh_new/boundary", "w+") as f:
        headers = get_OF_headers('polyBoundaryMesh', 'boundary', 5)
        f.writelines(headers)
        # print each patch
        # calc start point and number of data in each patch.
        start_patch_face = (nx-1) * ny * nz + (ny-1) * nz * nx + (nz-1) * nx * ny  # before this, all are internal faces
        # calc the number of internal faces to be deleted
        len_delete_from_internal = len([i for i in face_to_be_deleted if (i < start_patch_face)])

        # solubleWall
        start_face = (nx-1) * ny * nz + (ny-1) * nz * nx + (nz-1) * nx * ny
        new_start_face = start_face - len_delete_from_internal
        nfaces = 19040
        len_delete = len([i for i in face_to_be_deleted if (start_face <= i < start_face + nfaces)])
        new_nfaces = nfaces - len_delete
        f.writelines(get_OF_pathces("solubleWall", new_nfaces, new_start_face))

        # solubleWall_mirrored
        start_face += nfaces
        new_start_face += new_nfaces
        nfaces = 19040
        len_delete = len([i for i in face_to_be_deleted if (start_face <= i < start_face + nfaces)])
        new_nfaces = nfaces - len_delete
        f.writelines(get_OF_pathces("solubleWall_mirrored", new_nfaces, new_start_face))

        # inlet
        start_face += nfaces
        new_start_face += new_nfaces
        nfaces = 272
        len_delete = len([i for i in face_to_be_deleted if (start_face <= i < start_face + nfaces)])
        new_nfaces = nfaces - len_delete
        f.writelines(get_OF_pathces("inlet", new_nfaces, new_start_face))

        # outlet
        start_face += nfaces
        new_start_face += new_nfaces
        nfaces = 272
        len_delete = len([i for i in face_to_be_deleted if (start_face <= i < start_face + nfaces)])
        new_nfaces = nfaces - len_delete
        f.writelines(get_OF_pathces("outlet", new_nfaces, new_start_face))

        # insolubleY
        start_face += nfaces
        new_start_face += new_nfaces
        nfaces = 2240
        len_delete = len([i for i in face_to_be_deleted if (start_face <= i < start_face + nfaces)])
        new_nfaces = nfaces - len_delete
        f.writelines(get_OF_pathces("insolubleY", new_nfaces, new_start_face))

        f.writelines(footers)

    n_neighbour = len(df_neighbour.index) - len_delete_from_internal # since some faces doesn't have a neighbour, the length is not just a subtruction fo face_to_be_deleted.



    with open("polyMesh_new/points", "w+") as f:
        headers = get_OF_headers('vectorField', 'points', len(df_all_new.index))
        # Writing data to a file
        f.writelines(headers)
        df_all_new.index = df_all_new['index_column']
        for idx, row in df_all_new.sort_index().iterrows():
            f.write('(' + str(row['x']) + ' ' + str(row['y']) + ' ' + str(row['z']) + ')\n')
        f.writelines(footers)

    n_faces = len(df_faces.index) - df_faces['p3'].isna().sum()
    with open("polyMesh_new/faces", "w+") as f:
        headers = get_OF_headers('faceList', 'faces', n_faces)
        # Writing data to a file
        f.writelines(headers)
        for idx, row in df_faces.sort_index().iterrows():
            if np.isnan(row['p3']):
                continue
            elif np.isnan(row['p4']):
                f.write(str(int(row['np'])) + '(' + str(int(row['p1'])) + ' ' + str(int(row['p2'])) + ' ' + str(
                    int(row['p3'])) + ')\n')
            else:
                f.write(str(int(row['np'])) + '(' + str(int(row['p1'])) + ' ' + str(int(row['p2'])) + ' ' + str(
                    int(row['p3'])) + ' ' + str(int(row['p4'])) + ')\n')
        f.writelines(footers)


    nCells = nx * ny * nz
    with open("polyMesh_new/owner", "w+") as f:
        note = "nPoints:" + str(len(df_all_new.index)) + "  nCells:" + str(nCells) + "  nFaces:" + str(n_faces) + "  nInternalFaces:" + str(n_neighbour)
        headers = get_OF_headers('labelList', 'owner', n_faces, note=note)
        # Writing data to a file
        f.writelines(headers)
        for idx, row in df_owner.sort_index().iterrows():
            if idx not in face_to_be_deleted:
                f.write(str(int(row['cell'])) + '\n')
        f.writelines(footers)

    with open("polyMesh_new/neighbour", "w+") as f:
        headers = get_OF_headers('labelList', 'neighbour', n_neighbour, note=note)
        # Writing data to a file
        f.writelines(headers)
        for idx, row in df_neighbour.sort_index().iterrows():
            if idx not in face_to_be_deleted and idx < start_patch_face:
                f.write(str(int(row['cell'])) + '\n')
        f.writelines(footers)

    with open("polyMesh_new/face_to_be_deleted", "w+") as f:
        for idx in face_to_be_deleted:
            f.write(str(int(idx)) + '\n')

    # write surface output file for stl generation
    headers = ["Name: closed fracture\n",
               "Experiment number: 1\n",
               "Sample Lenght: 7.000000\n",
               "Sample Width: 1.700000\n",
               "Measurement Interval: 0.025000\n\n\n\n",
               "X Position	Y Position	Z Displacement"]

    with open("polyMesh_new/points_surface", "w+") as f:
        # Writing data to a file (order doesn't matter)
        f.writelines(headers)
        for i in df_new.index:
            df_new.loc[i, 'z'] -= 1
            df_new.loc[i, 'z'] *= -1

        for idx, row in df_new.sort_index().iterrows():
            f.write('{}'.format(str(row['x'])) + '\t' + str(row['y']) + '\t' + str(row['z']) + '\n')
