import os
import platform
# For Linux and Windows (no OF commands), but prefered to run on Linux since chmod and need to transfer more files
if platform.system() == 'Windows':
    import OFPy_deform_mesh
else:
    from . import OFPy_deform_mesh

dissolCases_directory = '//coe-fs.engr.tamu.edu/Grads/tohoko.tj/Documents/seed7000-stdev0_025/'
# batch_directory = '/scratch/user/tohoko.tj/dissolCases/dissolCases_230327/'

# close a fracture for the all projects in 'batch_directory' all at once.
def close_frac(dissolCases_directory):
    # get polyMesh from etching folder.
    os.chdir(dissolCases_directory)
    dir_list = os.listdir(dissolCases_directory)

    # run case
    for proj in dir_list:
        OFPy_deform_mesh.prep_case(proj, close=True)


if __name__ == "__main__":
    # test
    close_frac(dissolCases_directory)


