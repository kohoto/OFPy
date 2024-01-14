import os
import platform

if platform.system() == 'Windows':
    import OFPy_deform_mesh
    command_separator = '&'
else:
    from . import OFPy_deform_mesh
    command_separator = ';'

# For Linux and Windows (no OF commands), but prefered to run on Linux since chmod and need to transfer more files

def prep_batch(batch_directory, dissolCases_dir):
    """
    Use after OFPy_make_case.py.
    Create 'etching' and 'conductivity' directories.
    Copy OF input files from start_proj to each project directory in batch_directory.
    :param batch_directory: path to the directory you desire to copy OF input files from.
    :param dissolCases_dir: path to the parent "dissolCases" directory.
    :return: a set of the OF projects ready to run.
    """
    cond_list = ['conductivity' + str(pc * 1000) for pc in list(range(5))]
    cases = ['etching'] + cond_list
    # get polyMesh from etching folder.
    os.chdir(batch_directory)
    dir_list = os.listdir(batch_directory)
    dir_list = [d for d in dir_list if os.path.isdir(os.path.join(batch_directory, d))]
    start_proj_name = dissolCases_dir + '/start_proj'
    OFPy_batch_dir = dissolCases_dir + '/OFPy_batch'
    # sbatch files
    cmd = ['ln -s  ' + start_proj_name + '/EtchingBatch.sbatch ' + batch_directory + command_separator,
           'ln -s  ' + OFPy_batch_dir + '/All.sbatch ' + batch_directory + command_separator,
           'ln -s  ' + OFPy_batch_dir + '/All_small.sbatch ' + batch_directory + command_separator,
           'ln -s  ' + OFPy_batch_dir + '/ClosureCondBatch.sbatch ' + batch_directory + command_separator]
    os.system(''.join(cmd))

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
                   'mkdir -p ' + new_case_dir + '/constant' + command_separator,
                   'cp -rp ' + start_case_dir + '/constant/* ' + new_case_dir + '/constant/' + command_separator, # copy constant (cause polyMesh is unique)
                   'mkdir -p ' + new_case_dir + '/0' + command_separator,
                   'cp -rp ' + start_case_dir + '/Zero/* ' + new_case_dir + '/0/' + command_separator,             # hard copy 0 files (will be rewritten by OF simulation)
                   # remove constant except polyMesh & add symbolic links in constant except polyMesh
                   'rm ' + new_case_dir + '/constant/transportProperties' + command_separator,
                   'ln -s ' + start_case_dir + '/constant/transportProperties ' + new_case_dir + '/constant/transportProperties' + command_separator,

                   # add symbolic links for other dirs
                   'ln -s ' + start_case_dir + '/system ' + new_case_dir + command_separator,
                   # hard copy bash files
                   'ln -s  ' + start_case_dir + '/Clean ' + new_case_dir + command_separator,
                   'ln -s  ' + start_case_dir + '/PararellRun ' + new_case_dir + command_separator,
                   'ln -s  ' + start_case_dir + '/Single.sbatch ' + new_case_dir + command_separator,
                   'ln -s  ' + start_case_dir + '/Pararell.sbatch ' + new_case_dir + command_separator,
                   'chmod 775 ' + new_case_dir + '/PararellRun ' + new_case_dir + '/Clean']

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
    batch_dir = 'C:/Users/tohoko.tj/dissolCases/seed6000-stdev0_025'
    dissolCases_dir = 'C:/Users/tohoko.tj/dissolCases'

    prep_batch(batch_dir, dissolCases_dir)

