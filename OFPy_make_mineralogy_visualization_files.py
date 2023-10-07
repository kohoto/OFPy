import os
import write_IOObject as ioobject


def make_mineralogy_visualization_files(proj_path):
    # get mineralogy from dictionary
    mineralogy_list = ioobject.IOObject2dict(proj_path + '/etching/constant/rockProperties')
    mineralogy_list = mineralogy_list['mineralogy']  # check the order of values.

    # get the file contents except the header
    # cosntruct str list for data
    dict_mineralogy = {'internalField': 0,
                       'boundaryField':
                           {'solubleWall': {'type': 'fixedValue', 'value': mineralogy_list},
                            'solubleWall_mirrored': {'type': 'fixedValue', 'value': mineralogy_list},
                            'inlet': 0,
                            'outlet': 0,
                            'insolubleY': 0
                            }
                       }

    str_list_rest = ioobject.write_dict(dict_mineralogy)
    # footer
    # str_list_rest.append(ioobject.get_footer())

    os.chdir(case_directory)
    # get the header, concatenate to the rest, and write to the output files in each time directory
    times = [int(a) for a in os.listdir('etching') if a.isnumeric()]
    for time in times:
        # add header str to list
        str_list = ioobject.get_header("pointScalarField", time, "mineralogy")
        # concatenate the header and rest
        str_list = str_list + str_list_rest
        open(proj_path + '/etching/' + str(time) + '/mineralogy', 'w').write(''.join(str_list))


if __name__ == "__main__":
    # case_directory = 'C:/Users/tohoko.tj/dissolCases/no_roughness_mineralogy/no_roughness'
    case_directory = 'C:/Users/tohoko.tj/dissolCases/seed7500-stdev0_05/lambda1_0-0_5-stdev0_05/'
    make_mineralogy_visualization_files(case_directory)