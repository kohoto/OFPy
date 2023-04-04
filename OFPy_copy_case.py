import os

dissolCases_directory = '/home/tohoko/OpenFOAM/dissolFoam-v1912/dissolCases/'
old_proj_name = 'dissolFrac_testRoughSurfGen9'
new_proj_name = 'dissolFrac_testRoughSurfGen10'

# get polyMesh from etching folder.
os.chdir(dissolCases_directory)
os.system('mkdir ' + new_proj_name + '; cp ' + old_proj_name + '/inp ' + old_proj_name + '/inp')
cases = ['etching', 'conductivity']
for case in cases:
    old_case_dir = old_proj_name + '/' + case
    new_case_dir = new_proj_name + '/' + case

    cmd = ['mkdir ' + new_proj_name + '/' + case + ';',
           'cp -r ' + old_case_dir + '/constant ' + new_case_dir + ';',
           'cp -r ' + old_case_dir + '/system ' + new_case_dir + ';',
           'cp -r ' + old_case_dir + '/Zero ' + new_case_dir + ';',
           'cp ' + old_case_dir + '/Clean ' + new_case_dir + ';',
           'cp ' + old_case_dir + '/Run ' + new_case_dir + ';']
    os.system(''.join(cmd))
print('finished copying!')
