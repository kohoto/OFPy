import os
import platform

if platform.system() == 'Windows':
    import OFPy_deform_mesh
    command_separator = '&'
else:
    from . import OFPy_deform_mesh
    command_separator = ';'

# For Linux and Windows (no OF commands), but prefered to run on Linux since chmod and need to transfer more files

def prep_batch(dissolCases_directory, start_proj_name):
    """
    Use after OFPy_make_case.py.
    Create 'etching' and 'conductivity' directories.
    Copy OF input files from start_proj to each project directory in dissolCases_directory.

    :param dissolCases_directory: path to the directory you desire to copy OF input files from.
    :param start_proj_name: path to the template project directory.
    :return: a set of the OF projects ready to run.
    """
    cond_list = ['conductivity' + str(pc * 1000) for pc in list(range(1, 4))]
    cases = ['etching'] + cond_list
    # get polyMesh from etching folder.
    os.chdir(dissolCases_directory)
    dir_list = os.listdir(dissolCases_directory)
    dir_list = [d for d in dir_list if os.path.isdir(os.path.join(dissolCases_directory, d))]

    # copy cases
    for new_proj_name in dir_list:
        print('creating project files for ' + new_proj_name)
        for case in cases:
            if case == 'etching':
                start_case_dir = start_proj_name + '/etching'
            else:
                start_case_dir = start_proj_name + '/conductivity'

            new_case_dir = new_proj_name + '/' + case

            cmd = ['mkdir ' + new_case_dir + command_separator,
                   'cp -rp ' + start_case_dir + '/constant ' + new_case_dir + '/constant' + command_separator, # copy constant (cause polyMesh is unique)
                   'cp -rp ' + start_case_dir + '/Zero ' + new_case_dir + '/0' + command_separator,             # hard copy 0 files (will be rewritten by OF simulation)
                   # remove constant except polyMesh
                   'rm ' + new_case_dir + '/constant/transportProperties' + command_separator,
                   # add symbolic links in constant except polyMesh
                   'ln -s ' + start_case_dir + '/constant/transportProperties ' + new_case_dir +'/constant/transportProperties'  + command_separator,
                   # add symbolic links for other dirs
                   'ln -s ' + start_case_dir + '/system ' + new_case_dir + command_separator,
                   'ln -s ' + start_case_dir + '/Zero ' + new_case_dir + command_separator,
                   # hard copy bash files
                   'cp ' + start_case_dir + '/Clean ' + new_case_dir + command_separator,
                   'cp ' + start_case_dir + '/PararellRun ' + new_case_dir + command_separator,
                   'cp ' + start_case_dir + '/SingleRun ' + new_case_dir + command_separator,
                   'chmod 775 ' + new_case_dir + '/PararellRun ' + new_case_dir + '/SingleRun ' + new_case_dir + '/Clean']

            os.system(''.join(cmd))

            if case == 'etching': # copy files for dynamic mesh
                cmd = [# remove constant except polyMesh
                       'rm ' + new_case_dir + '/constant/dynamicMeshDict' + command_separator,
                       'rm -rf ' + new_case_dir + '/constant/bcInclude' + command_separator,
                       # add symbolic links in constant except polyMesh
                       'ln -s ' + start_case_dir + '/constant/dynamicMeshDict ' + new_case_dir + '/constant/dynamicMeshDict' + command_separator,
                       'ln -s ' + start_case_dir + '/constant/bcInclude ' + new_case_dir + '/constant/bcInclude' + command_separator]
            else:
                cmd = ['rm ' + new_case_dir + '/constant/turbulenceProperties' + command_separator,
                       'ln -s ' + start_case_dir + '/constant/turbulenceProperties ' + new_case_dir +'/constant/turbulenceProperties' + command_separator]

            os.system(''.join(cmd))


    # create rough surface mesh
    for proj in dir_list:
        OFPy_deform_mesh.prep_case(proj, close=False)


if __name__ == '__main__':
    dissolCases_directory = 'C:/Users/tohoko.tj/dissolCases/seed6000-stdev0_05'
    start_proj_name = 'C:/Users/tohoko.tj/dissolCases/start_proj'

    prep_batch(dissolCases_directory, start_proj_name)

