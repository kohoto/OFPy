import os
import shutil
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
                   'rm ' + new_case_dir + '/constant/transportProperties;',
                   # add symbolic links in constant except polyMesh
                   'ln -s ' + start_case_dir + '/constant/transportProperties ' + new_case_dir +'/constant/transportProperties;',
                   # add symbolic links for other dirs
                   'ln -s ' + start_case_dir + '/system ' + new_case_dir + '/system;',
                   'ln -s ' + start_case_dir + '/Zero ' + new_case_dir + '/Zero;',
                   # hard copy bash files
                   'cp ' + start_case_dir + '/Clean ' + new_case_dir + ';',
                   'cp ' + start_case_dir + '/PararellRun ' + new_case_dir + ';',
                   'cp ' + start_case_dir + '/SingleRun ' + new_case_dir + ';',
                   'chmod 775 ' + new_case_dir + '/PararellRun ' + new_case_dir + '/SingleRun ' + new_case_dir + '/Clean']

            os.system(''.join(cmd))
            # hard copy 0 files (will be rewritten by OF simulation)
            shutil.copytree(start_case_dir + '/Zero', new_case_dir + '/0', dirs_exist_ok=True)
            
            if case == 'etching': # copy files for dynamic mesh
                cmd = [# remove constant except polyMesh
                       'rm ' + new_case_dir + '/constant/dynamicMeshDict;',
                       'rm -rf ' + new_case_dir + '/constant/bcInclude;',
                       # add symbolic links in constant except polyMesh
                       'ln -s ' + start_case_dir + '/constant/dynamicMeshDict ' + new_case_dir + '/constant/dynamicMeshDict;',
                       'ln -s ' + start_case_dir + '/constant/bcInclude ' + new_case_dir + '/constant/bcInclude;']
            else:
                cmd = ['rm ' + new_case_dir + '/constant/turbulenceProperties;',
                       'ln -s ' + start_case_dir + '/constant/turbulenceProperties ' + new_case_dir +'/constant/turbulenceProperties;',]

            os.system(''.join(cmd))


    # create rough surface mesh
    for proj in dir_list:
        OFPy_deform_mesh.prep_case(proj, close=False)


if __name__ == '__main__':
    prep_batch(dissolCases_directory, start_proj_name)

