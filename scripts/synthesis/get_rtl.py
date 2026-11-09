import re
import os
import sys


# The generated .f lists live next to this script, not under the caller's cwd --
# the flow runs the tools from outputs/<stage>/, so relative paths would escape.
LISTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lists')


synopsys = True

# global variables
search_dirs         = []
file_path_list      = {} 
modules             = {}
module_names        = []


# if you're reading this code stop before its too late
# it will ruin you like it ruined me . .. . 


define_module_regex        = re.compile(r'^(?<!end)module ([^\s(#]+)( |\(|$|\#)', re.MULTILINE) 
define_interface_regex     = re.compile(r'^(?<!end)interface (\S+).*;', re.MULTILINE)  
define_package_regex       = re.compile(r'^(?<!end)package (\S+).*;', re.MULTILINE)     

def parse_file_for_defines(filepath):
    with open(filepath, 'r') as file: 
        file_contents = file.read();
    modules = {} 
    
    found = False
    for match in define_module_regex.finditer(file_contents):
        module_name = match.group(1)
        modules[module_name] = filepath
        found = True
    for match in define_interface_regex.finditer(file_contents):
        module_name = match.group(1)
        modules[module_name] = filepath
        found = True
    for match in define_package_regex.finditer(file_contents):
        module_name = match.group(1)
        modules[module_name] = filepath
        found = True

    filename_regex = re.compile(r'([^/\\]+?)\.([^.\\/]+)$')
    for match in filename_regex.finditer(filepath):
        module_name = match.group(1)
        modules[module_name] = filepath

    return modules 

def has_defines(filepath):
    with open(filepath, 'r') as file: 
        file_contents = file.read();
    modules = {} 
    
    found = False
    for match in define_module_regex.finditer(file_contents):
        module_name = match.group(1)
        modules[module_name] = filepath
        found = True
    for match in define_interface_regex.finditer(file_contents):
        module_name = match.group(1)
        modules[module_name] = filepath
        found = True
    for match in define_package_regex.finditer(file_contents):
        module_name = match.group(1)
        modules[module_name] = filepath
        found = True

    return found


def find_modules():
    modules_found = {}
    for topdir in search_dirs:
        for dirpath, dirnames, filenames in os.walk(topdir):
            for filename in filenames:
                file_path_list[filename] = (os.path.join(dirpath, filename))
                if filename.endswith(('.sv', '.v', '.svh')):
                    modules_found.update(parse_file_for_defines(os.path.join(dirpath, filename)))

    return modules_found
            
            

import_regex        = re.compile(r'^([ \t]*)import (\S+)::.*', re.MULTILINE)
include_regex       = re.compile(r'^`include "(\S+)\.(\S+)"', re.MULTILINE)

def parse_file_for_dependences(filepath):
    with open(filepath, 'r') as f:
        file_contents = f.read()

    import_dependencies = []
    include_dependencies = []
    
    # add imported modules to dependencies
    for match in import_regex.finditer(file_contents):
        matchname = match.group(2)
        if matchname in modules:
            import_dependencies.append(modules[matchname])
        else:
            print(f"ERROR: dependency {matchname} does not exist in search directories")
            sys.exit(1)

    # add included modules to dependecies if they're not already in there from imports
    for match in include_regex.finditer(file_contents):
        matchname = match.group(1)

        matches = []

        if '.' in matchname:
            matchname = matchname.split('.')[0]

            for module in parse_file_for_defines(modules[matchname]):
                matches.append(modules[matchname])
        else:
            matches.append(matchname) 

        for matchname in matches:
            if matchname in module_names:
                include_dependencies.append(modules[matchname])
            else:
                print(f"ERROR: dependency {matchname} does not exist in search directories")
                sys.exit(1)


                   # order doesn't matter
    dependencies = import_dependencies + include_dependencies

    for module in module_names:
        # An instantiation's type name is the first token on its line. Anchoring
        # on that is what keeps prose ("// top wall"), commented-out instances,
        # and instance names that collide with a filename out of the list -- and
        # it excludes the definition line, whose first token is the keyword.
        instantiation_regex = re.compile(
            rf"^[ \t]*({re.escape(module)})(?=[\s#(.])", re.MULTILINE
        )
        for match in instantiation_regex.finditer(file_contents):
            matchname = match.group(1)

            if matchname in modules.keys() and modules[matchname] not in dependencies:
                dependencies.append(modules[matchname])
            
    return dependencies
           
            

     

    

# engineer writes slowest function ever, asked to leave club
def collect_hierarchy(module_path, seen=None):
    if seen is None:
        seen = set()
    
    if module_path in seen:
        return []
    
    seen.add(module_path)
    module_dependency_filepaths = parse_file_for_dependences(module_path)
    
    hierarchy = []

    for dep_path in module_dependency_filepaths:
        # Recurse first to find the deepest dependencies
        child_deps = collect_hierarchy(dep_path, seen)
        for child in child_deps:
            if child not in hierarchy:
                hierarchy.append(child)
        
        # Then add the dependency itself (it's now "ready" because its children are added)
        if dep_path not in hierarchy:
            hierarchy.append(dep_path)

    return hierarchy









if __name__ == "__main__":
    # check that arguments were provided
    if len(sys.argv) < 3:
        print("Usage: get_rtl.py <top_module> <codebase_paths>", file=sys.stderr)
        print("Example: python3.12 get_rtl.py execute_stage /path/to/SJapr/tapeouts/to2/src /path/to/SJapr/tapeouts/to2/packages")
        sys.exit(1)
        


    # ingest toplevel module name and codebase path
    toplevel_module_name = sys.argv[1]
    del sys.argv[0]
    del sys.argv[0]
    
    search_dirs = sys.argv

    # modules is a dict with <modulename>: <filepath>
    modules = find_modules()
    module_names = list(modules.keys())
    print(modules)
    try:
        toplevel_module_path = modules[toplevel_module_name]
    except:
        print(f"ERROR: RTL module {toplevel_module_name} not found in RTL search paths.")
        sys.exit(1)
    hierarchy = collect_hierarchy(toplevel_module_path)
    
    if modules[toplevel_module_name] not in hierarchy:
        hierarchy.append(modules[toplevel_module_name])

    

    
    assumed_headers = []

    for filepath in hierarchy:
        if not has_defines(filepath):
            assumed_headers.append(filepath) 
            hierarchy.remove(filepath)
    
    headers = []
    for path in hierarchy:
        if ".svh" in path:
            headers.append(path)
            hierarchy.remove(path)

    assumed_headers.extend(hierarchy)
    headers.extend(assumed_headers)
    hierarchy = headers


    os.makedirs(LISTS_DIR, exist_ok=True)

    # synopsys finds headers itself for some reason
    if (synopsys):
        try:
            with open(os.path.join(LISTS_DIR, 'header_directory_list.f'), 'w') as header_directory_list:
                with open(os.path.join(LISTS_DIR, 'header_list.f'), 'w') as header_list:
                    headers = []
                    for filepath in hierarchy[:]:
                        if filepath.endswith('.svh'):
                            piece_list = filepath.split('/')
                            path = filepath.replace(piece_list[len(piece_list)-1], '', 1)
                            header_list.write(f"{filepath}\n")
                            if path not in headers:
                                headers.append(path)
                                header_directory_list.write(f"{path}\n")
                            hierarchy.remove(filepath)
        except Exception:
            pass

    with open(os.path.join(LISTS_DIR, 'file_list.f'), 'w') as file_list:
        for filepath in hierarchy:
            file_list.write(f"{filepath}\n")
