import re

def write_IOObject(cls, loc, obj, ):
    header = get_header(cls, loc, obj)

    return 0


def write_boundaryField():

    return 0

def write_scalar_field(field_name, value):
    return "{}   uniform {};".format(field_name, value)

def write_list_field(field_name, type, value_list):
    non_uniform_field = ["{}           nonuniform List<scalar>\n{}\n(".format(len(value_list))]

    # write list here

    return str_list


def write_polyMesh():
    return 0


def IOObject2dict(file_path):
    result_dict = {}
    current_dict = result_dict
    stack = []
    pattern = r'//.*|/\*[\s\S]*?\*/'
    with open(file_path, 'r') as file:
        # Regular expression to match single-line and multi-line comments
        lines = file.read()
        # Remove comments using re.sub
        lines = re.sub(pattern, '', lines)
        content = lines.replace('\n', ' ')
    while content != "":
        current_dict, content = read_dict(content)
    return current_dict


def read_dict(content):
    current_dict = {}  # create a new dict
    # while not content.startwith("}"):  # do until the end of the dict
    while not (content.startswith("}") or content == ""):
        entry_idx = content.find(';')
        if entry_idx == -1:
            entry_idx = 1000000000
        dict_idx = content.find('{')
        if dict_idx == -1:
            dict_idx = 1000000000
        close_idx = content.find('}')
        if close_idx == -1:
            close_idx = 1000000000

        if dict_idx == entry_idx:
            print('something wrong')

        delim_idx = min(entry_idx, dict_idx, close_idx)
        if delim_idx == entry_idx:  # read entry
            key, value = read_entry(content[:entry_idx].strip())
            content = content[entry_idx + 1:].strip()
            current_dict[key] = value
        elif delim_idx == dict_idx:  # read dictionary
            key = content[:dict_idx].strip()
            current_dict[key], content = read_dict(content[dict_idx + 1:].strip())
            content = content[1:]  # remove }

        else:
            content = ""
            break

    return current_dict, content


def read_dict_entries(content):
    current_dict = {}
    while not content.startwith('}'):
        delim_idx = content.find(';')
        key, value = read_entry(content[:delim_idx].strip())
        current_dict[key] = value
        content = content[delim_idx + 1:]
    return current_dict


def read_entry(entry):
    is_list = entry.find('(')
    if is_list != -1:
        # This is list
        key = entry[:is_list].strip()
        value = entry[is_list + 1:-1].strip()  # exclude the last element since it will be ')'
        value = value.split(' ')
        while ("" in value):
            value.remove("")

        value = [int(x) for x in value]
    else:
        # scalar entry
        str_list = entry.split(' ')
        while ("" in str_list):
            str_list.remove("")
        key = str_list[0]
        value = str_list[1]
    return key, value


def extract_content_between_delimiters(content):
        # Use regular expressions to find dictionary title
        pattern = r'(.*?){'
        keys = re.findall(pattern, content)

        # Use regular expressions to find content between '<<' and '>>'
        pattern = r'{(.*?)}'
        values = re.findall(pattern, content)

        return keys, values


def write_dict(dictionary, level=0):
    indent = ' ' * (level * 4)
    str_list = []

    for key, value in dictionary.items():
        if isinstance(value, dict):
            str_list.append(indent + key + '\n' + indent + '{\n')
            str_list = str_list + write_dict(value, level + 1)
            str_list.append(indent + '}\n')
        elif isinstance(value, list):
                str_list.append(indent + key + '    nonuniform List<scalar>\n' + indent + str(len(value)) + '\n' + indent + '(\n')
                value = ['{}    {}\n'.format(indent, str(x)) for x in value]
                str_list = str_list + value  # assuming value is a list of scalars
                str_list = str_list + [indent + ');\n']
        else: # just write key and value
            str_list.append(indent + key + '    ' + str(value) + ';\n')

    return str_list



def read_dictionary(content):
    for key, value in content.items():
        if isinstance(value, dict):  # keep digging
            return {key: read_dictionary(value)}
        else:
            return {key: value}
    return 0

def get_header(cls, loc, obj, note=""):
    h0 = ["/*--------------------------------*- C++ -*----------------------------------*\n",
               "| =========                 |                                                 |\n",
               "| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |\n",
               "|  \\    /   O peration     | Version:  v1912                                 |\n",
               "|   \\  /    A nd           | Website:  www.openfoam.com                      |\n",
               "|    \\/     M anipulation  |                                                 |\n",
               "\*---------------------------------------------------------------------------*/\n",
               "FoamFile\n",
               "{\n",
               "    version     2.0;\n",
               "    format      ascii;\n",
               "    class       {};\n".format(cls)]
    h1 = ['    note        "{}";\n'.format(note)]
    h2 = ['    location    "{}";\n'.format(loc),
               "    object      {};\n".format(obj),
               "}\n",
               "// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //\n\n"]

    if note != "":
        headers = h0 + h1 + h2
    else:
        headers = h0 + h2

    return headers

def write_OF_dictionary(cls, loc, obj, dict):
    headers = get_header(cls, loc, obj)
    if cls == "surfaceScalarField":
        dimensions = ["\ndimensions      [0 0 0 0 0 0 0];\n\n"]
    else:
        dimensions = []

    str_list = write_dict(dict, level=0)
    return headers + dimensions + str_list


def write_file(str_list, file_path):
    open(file_path, 'w').write(''.join(str_list))
