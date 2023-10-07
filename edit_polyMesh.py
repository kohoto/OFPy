import numpy as np
import pandas as pd


def read_OF_boundary(fpath, nrows):
    return 0


def read_OF_points(fpath, nrows):
    df = pd.read_csv(fpath, nrows=nrows, skiprows=20, sep=" ", header=None, names=["x", "y", "z"], on_bad_lines='skip')
    # df.drop(df.tail(2).index, inplace=True)  # drop last 2 rows
    # df = df[:-2]  # somehow nrows and skipfooter didn't work well
    df["x"] = df["x"].astype(str).str.replace("(", '').astype(float)
    df["y"] = df["y"].astype(float)
    df["z"] = df["z"].astype(str).str.replace(")", '').astype(float)

    # extract the points only from surface (this affects only for points_surface)
    # df.drop(df[df["z"] > 0.1].index, inplace=True)
    # df = df.drop_duplicates().reset_index(drop=True)
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


def get_OF_headers(object, ndata, note=""):
    if object == "boundary":  # polyBoundaryMesh
        cls = 'polyBoundaryMesh'
    elif object == "points":
        cls = 'vectorField'
    elif object == "faces":
        cls = 'faceList'
    elif object == "neighbour" or object == "owner":
        cls = 'labelList'
    elif object == "etched_wids":
        cls = 'volScalarField'
    elif object == "mineralogy":
        cls = 'dictionary'
    else:
        print('no write function for this object [edit_polyMesh/get_OF_headers]')

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


def get_OF_patches(patch_name, n_faces, start_face):
    patch = ["    {}\n".format(patch_name),
             "    {\n",
             "        type            patch;\n",
             "        nFaces          {};\n".format(n_faces),
             "        startFace       {};\n".format(start_face),
             "    }\n"]

    return patch


def get_OF_footers():
    return [")\n\n",
            "// ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** * //"]


def write_OF_polyMesh(object, ndata, df, note="", delete_idx=[]):
    with open("constant/polyMesh/" + object, "w+") as f:
        f.writelines(get_OF_headers(object, ndata, note))

        if object == "boundary":  # polyBoundaryMesh
            for patch, nfaces, start_face in zip(df['patch'], df['nfaces'], df['start_face']):
                f.writelines(get_OF_patches(patch, nfaces, start_face))

        # elif object == "points":
        #     f.write(''.join('(' + str(row['x']) + ' ' + str(row['y']) + ' ' + str(row['z']) + ')\n' for idx, row in df.sort_index().iterrows())
        #
        elif object == "points":
            line = '({row0:.9f} {row1:.9f} {row2:.9f})\n'
            f.write(
                ''.join(line.format(row0=row[0], row1=row[1], row2=row[2]) for idx, row in df.sort_index().iterrows()))

        elif object == "faces":
            for idx, row in df.sort_index().iterrows():
                if np.isnan(row['p3']):
                    continue
                elif np.isnan(row['p4']):
                    f.write(str(int(row['np'])) + '(' + str(int(row['p1'])) + ' ' + str(int(row['p2'])) + ' ' + str(
                        int(row['p3'])) + ')\n')
                else:
                    f.write(str(int(row['np'])) + '(' + str(int(row['p1'])) + ' ' + str(int(row['p2'])) + ' ' + str(
                        int(row['p3'])) + ' ' + str(int(row['p4'])) + ')\n')

        elif object == "neighbour":
            for idx, row in df.sort_index().iterrows():
                if idx not in delete_idx and idx < start_patch_face:
                    f.write(str(int(row['cell'])) + '\n')

        elif object == "owner":
            for idx, row in df.sort_index().iterrows():
                if idx not in delete_idx:
                    f.write(str(int(row['cell'])) + '\n')
        else:
            print('no write function for this object [edit_polyMesh/write_OF_polyMesh]')

        f.writelines(get_OF_footers())


if __name__ == '__main__':
    ly = 1.60 * 0.0254
    lx = 7.0 * 0.0254
    ny = 68
    nx = 280
    nz = 4
    nInternalFaces = nx * nz * (ny - 1) + nx * ny * (nz - 1) + ny * nz * (nx - 1)
    # read polyMesh files
    df_points = read_OF_points("polyMesh/points", nrows=(nx + 1) * (ny + 1) * (nz + 1))
    df_points['index_column'] = df_points.index
    df_faces = read_OF_faces("polyMesh/faces", nrows=nx * nz * (ny + 1) + nx * ny * (nz + 1) + ny * nz * (nx + 1))

    face_to_be_deleted = get_duplicated_points()

    # example to write boundary
    start_patch_face = (nx - 1) * ny * nz + (ny - 1) * nz * nx + (
            nz - 1) * nx * ny  # before this, all are internal faces
    # calc the number of internal faces to be deleted
    len_delete_from_internal = len([i for i in face_to_be_deleted if (i < start_patch_face)])

    old_nfaces_list = [nx * ny, nx * ny, ny * nz, ny * nz, nz * nx, nz * nx]

    # do something special for the first patch
    start_faces = [(nx - 1) * ny * nz + (ny - 1) * nz * nx + (nz - 1) * nx * ny - len_delete_from_internal]
    len_delete = len([i for i in face_to_be_deleted if (start_faces[0] <= i < start_faces[0] + old_nfaces_list[0])])
    nfaces = [old_nfaces_list[0] - len_delete]

    for old_nfaces in old_nfaces_list[1:]:
        start_faces.append(start_faces[-1] + old_nfaces)
        len_delete = len([i for i in face_to_be_deleted if (start_faces[-1] <= i < start_faces[-1] + old_nfaces)])
        nfaces.append(old_nfaces - len_delete)

    df_patch = pd.DataFrame(data={'patch': ['solubleWall', 'solubleWall_mirrored', 'inlet', 'outlet', 'insolubleY'],
                                  'nfaces': nfaces,
                                  'start_face': start_faces})
    headers = get_OF_headers('polyBoundaryMesh', 'boundary', 5)
    write_OF_polyMesh('boundary', len(df_patch), df_patch)

    # example to write faces
    n_faces = len(df_faces.index) - df_faces['p3'].isna().sum()
    write_OF_polyMesh('faces', len(df_faces), df_faces)

    # example of write owner
    df_owner = read_OF_cells("polyMesh/owner", nrows=nx * nz * (ny + 1) + nx * ny * (nz + 1) + ny * nz * (nx + 1))

    nCells = nx * ny * nz
    note = "nPoints:" + str(len(df_points.index)) + "  nCells:" + str(nCells) + "  nFaces:" + str(
        n_faces) + "  nInternalFaces:" + str(nInternalFaces)
    write_OF_polyMesh('owner', n_faces, df_owner, note=note, delete_idx=face_to_be_deleted)

    # example of write neighbour
    # since some faces doesn't have a neighbour, the length is not just a subtruction fo face_to_be_deleted.
    df_neighbour = read_OF_cells("polyMesh/neighbour", nrows=nInternalFaces)
    n_neighbour = len(df_neighbour.index) - len_delete_from_internal
    nCells = nx * ny * nz
    note = "nPoints:" + str(len(df_points.index)) + "  nCells:" + str(nCells) + "  nFaces:" + str(
        n_faces) + "  nInternalFaces:" + str(nInternalFaces)
    write_OF_polyMesh('owner', n_faces, df_neighbour, note=note, delete_idx=face_to_be_deleted)

    # write surface output file for stl generation
    stl_headers = ["Name: closed fracture\n",
                   "Experiment number: 1\n",
                   "Sample Lenght: 7.000000\n",
                   "Sample Width: 1.700000\n",
                   "Measurement Interval: 0.025000\n\n\n\n",
                   "X Position	Y Position	Z Displacement"]
