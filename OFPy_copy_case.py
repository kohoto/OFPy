import os

dissolCases_directory = '/home/tohoko/OpenFOAM/dissolFoam-v1912/dissolCases/' # abs path that is the same for both dir
old_proj_name = 'dissolFrac_testRoughSurfGen9'
new_proj_name = 'dissolFrac_testRoughSurfGen10'

def copy_case(dissolCases_directory, old_proj_name, new_proj_name): 
    # get polyMesh from etching folder.
    os.chdir(dissolCases_directory)
    print(os.getcwd())
    os.system('mkdir ' + new_proj_name + '; cp ' + old_proj_name + '/inp ' + new_proj_name + '/inp'
              + '; cp ' + old_proj_name + '/roughness ' + new_proj_name + '/roughness'
              + '; cp ' + old_proj_name + '/sgsim.par ' + new_proj_name + '/sgsim.par')
    cases = ['etching', 'conductivity']
    for case in cases:
        old_case_dir = old_proj_name + '/' + case
        new_case_dir = new_proj_name + '/' + case

        cmd = ['mkdir ' + new_proj_name + '/' + case + ';',
            'cp -r ' + old_case_dir + '/constant ' + new_case_dir + ';',
            'cp -r ' + old_case_dir + '/system ' + new_case_dir + ';',
            'cp -r ' + old_case_dir + '/Zero ' + new_case_dir + ';',
            'cp ' + old_case_dir + '/Clean ' + new_case_dir + ';',
            'cp ' + old_case_dir + '/PararellRun ' + new_case_dir + ';',
            'cp ' + old_case_dir + '/SingleRun ' + new_case_dir + ';']
        os.system(''.join(cmd))
    print('finished copying!')
