import os
from . import OFPy_deform_mesh
# For Linux and Windows (no OF commands), but prefered to run on Linux since chmod and need to transfer more files

# dissolCases_directory = 'C:/Users/tohoko.tj/Documents/dissolCases_230329'
dissolCases_directory = '/scratch/user/tohoko.tj/dissolCases/seed7500-stdev0_025/'
start_proj_name = '/scratch/user/tohoko.tj/dissolCases/start_proj'


def prep_batch(dissolCases_directory, start_proj_name):
    cases = ['etching', 'conductivity']
    # get polyMesh from etching folder.
    os.chdir(dissolCases_directory)
    dir_list = os.listdir(dissolCases_directory)

    # copy cases
    for new_proj_name in dir_list:
        for case in cases:
            start_case_dir = start_proj_name + '/' + case
            new_case_dir = new_proj_name + '/' + case

            cmd = ['cp -rp ' + start_case_dir + '/constant ' + new_case_dir + '/constant;', # copy constant (cause polyMesh is unique)
                   # remove constant except polyMesh
                   'rm ' + new_case_dir + '/constant/dynamicMeshDict;',
                   'rm ' + new_case_dir + '/constant/transportProperties;',
                   'rm -rf' + new_case_dir + '/constant/bcInclude;',
                   # add symbolic links in constant except polyMesh
                   'ln -s ' + start_case_dir + '/constant/dynamicMeshDict ' + new_case_dir + '/constant/dynamicMeshDict;',
                   'ln -s ' + start_case_dir + '/constant/transportProperties ' + new_case_dir + '/constant/transportProperties;',
                   'ln -s ' + start_case_dir + '/constant/bcInclude ' + new_case_dir + '/constant/bcInclude;',
                   # add symbolic links for other dirs
                   'ln -s ' + start_case_dir + '/system ' + new_case_dir + ';',
                   'ln -s ' + start_case_dir + '/Zero ' + new_case_dir + ';',
                   # hard copy bash files
                   'cp ' + start_case_dir + '/Clean ' + new_case_dir + ';',
                   'cp ' + start_case_dir + '/PararellRun ' + new_case_dir + ';',
                   'cp ' + start_case_dir + '/SingleRun ' + new_case_dir + ';',
                   # hard copy 0 folder (it will be rewritten by OF)
                   'cp -rp ' + start_case_dir + '/Zero ' + new_case_dir + '/0;',
                   'chmod 775 ' + new_case_dir + '/PararellRun ' + new_case_dir + '/SingleRun ' + new_case_dir + '/Clean']
            os.system(''.join(cmd))


    # create rough surface mesh
    for proj in dir_list:
        OFPy_deform_mesh.prep_case(proj, close=False)


if __name__ == '__main__':
    prep_batch(dissolCases_directory, start_proj_name)

