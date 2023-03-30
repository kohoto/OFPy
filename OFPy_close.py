import os
# For Linux and Windows (no OF commands), but prefered to run on Linux since chmod and need to transfer more files
from . import OFPy_deform_mesh
# dissolCases_directory = 'C:/Users/tohoko.tj/Documents/dissolCases_230329'
dissolCases_directory = '/scratch/user/tohoko.tj/dissolCases/dissolCases_230327/'

def close_frac(dissolCases_directory):
    # get polyMesh from etching folder.
    os.chdir(dissolCases_directory)
    dir_list = os.listdir(dissolCases_directory)

    # run case
    for proj in dir_list:
        OFPy_deform_mesh.prep_case(proj, close=True)