import os
from OFPy_close import prep_case
# For Linux and Windows (no OF commands), but prefered to run on Linux since chmod and need to transfer more files

dissolCases_directory = '//coe-fs.engr.tamu.edu/Grads/tohoko.tj/Documents/dissolCases_230327/'
# dissolCases_directory = '/scratch/user/tohoko.tj/dissolCases/dissolCases_230327/'
start_proj_name = 'lambda1_0-1_0-stdev0_025'
cases = ['etching', 'conductivity']

# get polyMesh from etching folder.
os.chdir(dissolCases_directory)
dir_list = os.listdir(dissolCases_directory)
dir_list.remove(start_proj_name)

for case in cases:
    os.system('chmod 775 ' + start_proj_name + '/' + case + '/Run ' + start_proj_name + '/' + case + '/Clean')

# copy cases
for new_proj_name in dir_list:
    for case in cases:
        start_case_dir = start_proj_name + '/' + case
        new_case_dir = new_proj_name + '/' + case

        cmd = ['cp -r ' + start_case_dir + '/constant ' + new_case_dir + ';',
               'cp -r ' + start_case_dir + '/system ' + new_case_dir + ';',
               'cp -r ' + start_case_dir + '/Zero ' + new_case_dir + ';',
               'cp ' + start_case_dir + '/Clean ' + new_case_dir + ';',
               'cp ' + start_case_dir + '/Run ' + new_case_dir + ';',
               'mkdir ' + new_case_dir + '/0;',
               'chmod 775 ' + new_case_dir + '/Run ' + new_case_dir + '/Clean']
        os.system(''.join(cmd))


# run case
dir_list.append(start_proj_name)
for proj in dir_list:
    prep_case(proj, close=False)

