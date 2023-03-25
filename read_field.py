import numpy as np
import pandas as pd
from edit_polyMesh import get_OF_headers

def read_OF_U(fpath, nrows):
    df = pd.read_csv(fpath, skiprows=23, nrows=nrows, sep=" ", header=None, names=["x", "y", "z"])

    df["x"] = df["x"].astype(str).str.replace("(", '').astype(float)
    df["y"] = df["y"].astype(float)
    df["z"] = df["z"].astype(str).str.replace(")", '').astype(float)
    return df

def read_OF_p(fpath, nrows):
    df = pd.read_csv(fpath, skiprows=23, nrows=nrows, sep=" ", header=None, names=["p"])
    return df["p"].astype(float)


def write_OF_field(object, ndata, df, path, delete_idx = []):
    with open(path + object, "w+") as f:
        f.writelines(get_OF_headers(object, ndata))

        if object == "etched_wids":
            line = '{row0:.9f}\n'
            f.write(''.join(line.format(row0=row[0]) for idx, row in df.sort_index().iterrows()))
        else:
            line = '({row0:.9f} {row1:.9f} {row2:.9f})\n'
            f.write(''.join(line.format(row0=row[0], row1=row[1], row2=row[2]) for idx, row in df.sort_index().iterrows()))
