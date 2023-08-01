#!/usr/bin/env python3

import argparse
import datetime
import json
import os
import platform
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('-y', '--skip-prompt', action='store_true',
                    help='Skip prompt before deleting old dependencies folder')
parser.add_argument('-d', '--download', action='store_true',
                    help='Download dependencies from AWS instead of searching locally')
parser.add_argument('-c', '--compress', action='store_true', help='Compress dependencies to upload to AWS')
parser.add_argument('-l', '--lipo', action='store_true',
                    help='Combine Apple Silicon and Intel .dylib binaries into universal binaries')
parser.add_argument('-x', '--x86', action='store_true', help='Gather x86 dependencies only')
parser.add_argument('-a', '--arm', action='store_true', help='Gather ARM dependencies only')
args = parser.parse_args()

exclusive_args = ['download', 'compress', 'lipo']

if sum([getattr(args, arg) for arg in exclusive_args]) > 1:
    print('The following commands should not be used together:')
    for arg in exclusive_args:
        print(f'  --{arg}')
    exit(1)

# active_archs matches the keys in dependencies.json "search_paths" dict
# If neither --arm nor --x86, enable both
active_archs = ['arm', 'x86']
if args.arm != args.x86 and not args.lipo:
    active_archs = ['arm'] if args.arm else ['x86']

##
k_framework_extension = '.framework'
k_framework_separator = f'{k_framework_extension}{os.sep}'


##
def remove_trailing_separator(src_path):
    path = src_path
    if path.endswith(os.sep):
        path = path[:-1]
    return path


##
def is_framework_path(src_path):
    path = remove_trailing_separator(src_path)
    return path.endswith(k_framework_extension)


##
def is_framework_child_path(src_path):
    path = remove_trailing_separator(src_path)
    return k_framework_separator in path


##
def find_framework_parent_path(src_path):
    path = src_path
    while k_framework_separator in path:
        if not is_framework_path(path):
            path = os.path.dirname(path)
    return path


##
def find_framework_dylib_path(src_path):
    dylib_path = None
    framework_path = find_framework_parent_path(src_path)
    if is_framework_path(framework_path):
        # For the dylibs we're searching for inside of Python.framework, the file named like
        # libpython3.11.dylib ends up being a symlink to a binary file just called 'Python'
        # This map holds realpath (follow symlinks) -> os.walk path (may be a symlink)
        path_map = dict()
        for root_path, dir_names, file_names in os.walk(framework_path):
            dylib_names = [f for f in file_names if f.startswith('lib') and f.endswith('.dylib')]
            for dylib_name in dylib_names:
                dylib_path = os.path.join(root_path, dylib_name)
                dylib_key = os.path.realpath(dylib_path)
                existing = path_map.get(dylib_key, None)
                # Here we save the shortest path, so we end up with:
                #   Python.framework/Versions/3.11/lib/libpython3.11.dylib
                # Instead of:
                #   Python.framework/Versions/3.11/lib/python3.11/config-3.11-darwin/libpython3.11.dylib
                if not existing or len(dylib_path) < len(existing):
                    path_map[dylib_key] = dylib_path
        if len(path_map) > 1:
            raise RuntimeError(f'Too many .dylibs in framework: {path_map}')
        _, dylib_path = path_map.popitem()
        print(f'Framework {framework_path} dylib found:')
        print(f'  {dylib_path}')
    return dylib_path


##
def run_cmd(cmd, validate_stderr=None):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (proc_out, proc_err) = proc.communicate()

    err_lines = [line.strip() for line in proc_err.decode('ascii').splitlines()]

    failed = (proc.returncode != 0)
    if not failed and err_lines:
        # Default to failed if there was stderr output, but the caller may have
        # provided a callback to validate expected (warning) stderr output.
        failed = True
        if validate_stderr and validate_stderr(err_lines):
            failed = False

    if failed:
        print(f'ERROR in run_cmd ({proc.returncode}):')
        print(f'  Command: {cmd}')
        for line in err_lines:
            print(line)
        exit(1)

    return [line.strip() for line in proc_out.decode('ascii').splitlines()]


##
def parse_major_version(version):
    if '.' in version:
        return version.split('.')[0]
    return version


##
def is_system_library(path):
    system_paths = [
        '/system/',
        '/usr/lib/'
    ]
    path = path.lower()
    return any([path.startswith(sp) for sp in system_paths])


##
def validate_install_name_tool_stderr(lines):
    # This command prints a message about.
    # "changes being made to the file will invalidate the code signature"
    # But Xcode will sign on copy so that's not a concern.
    expected_warnings = [
        'install_name_tool: warning: changes being made to the file will invalidate the code signature'
    ]
    for line in lines:
        expected = any([(ew in line) for ew in expected_warnings])
        if not expected:
            return False
    return True


##
def find_dylib_actual_name(dylib_path):
    if is_framework_child_path(dylib_path):
        dylib_path = find_framework_dylib_path(dylib_path)
        if os.path.isdir(dylib_path):
            raise RuntimeError(f'Unhandled framework dir: {dylib_path}')
        dylib_path = os.path.split(dylib_path)[1]
    return os.path.split(dylib_path)[1]


##
def stamp_dylib_id(path):
    stamp_name = find_dylib_actual_name(path)
    cmd = [
        'install_name_tool',
        '-id',
        f'@rpath/{stamp_name}',
        path
    ]
    run_cmd(cmd, validate_stderr=validate_install_name_tool_stderr)


##
def stamp_dylib_change(path, dependency_path):
    stamp_name = find_dylib_actual_name(dependency_path)
    cmd = [
        'install_name_tool',
        '-change',
        dependency_path,
        f'@rpath/{stamp_name}',
        path
    ]
    run_cmd(cmd, validate_stderr=validate_install_name_tool_stderr)


##
def copy_dylib(src_path, dest_path):
    if is_framework_child_path(src_path):
        dylib_path = find_framework_dylib_path(src_path)

        if os.path.isdir(dylib_path):
            raise RuntimeError(f'Unhandled framework dir: {dylib_path}')

        else:
            src_path = dylib_path
            src_dylib_name = os.path.split(src_path)[1]
            dest_dir = os.path.dirname(dest_path)
            dest_path = os.path.join(dest_dir, src_dylib_name)

    print(f'Copying {src_path} to {dest_path}')
    if os.path.exists(dest_path):
        print('Destination file already exists!')
        exit(1)
    shutil.copyfile(src_path, dest_path)
    return dest_path


##
def locate_dependency(dylib_name, search_paths):
    found = None

    for search_path in search_paths:

        search_lib_path = os.path.join(search_path, 'lib')

        dylib_path = os.path.join(search_lib_path, dylib_name)

        if os.path.exists(dylib_path):
            print(f'  Found {dylib_path}')
            found = dylib_path
            break

    if not found:
        print(f'ERROR: No match found for {dylib_name}!')
        exit(1)

    return found


##############################

scripts_path = os.path.dirname(os.path.abspath(sys.argv[0]))

dependencies_json_path = os.path.join(scripts_path, 'dependencies.json')
with open(dependencies_json_path, 'r') as json_file:
    dependencies_json = json.load(json_file)

search_paths = dependencies_json['search_paths']
dependency_versions = dependencies_json['dependencies']
header_libraries = dependencies_json['headers']
download_url = dependencies_json['download_url']

root_path = os.path.dirname(scripts_path)
destination_path = os.path.join(root_path, 'Dependencies')

print(f'Scripts path: {scripts_path}')
print(f'Destination path: {destination_path}')

if os.path.exists(destination_path) and not (args.compress or args.lipo):
    print('Deleting existing Dependencies directory:')
    print(f'  {destination_path}')
    if not args.skip_prompt:
        input('Press enter to continue...')
    shutil.rmtree(destination_path)

lib_destination_path = os.path.join(destination_path, 'lib')
include_destination_path = os.path.join(destination_path, 'include')

platform_name, other_platform_name = 'arm', 'intel'
if platform.processor() != 'arm':
    platform_name, other_platform_name = other_platform_name, platform_name

print(f'Libraries path: {lib_destination_path}')
print(f'Includes path: {include_destination_path}')

if args.download:
    download_filename = os.path.basename(download_url)
    download_path = os.path.abspath(os.path.join(scripts_path, download_filename))

    print('Downloading...')
    print(f'URL:  {download_url}')
    print(f'Path: {download_path}')

    proc = subprocess.Popen(['wget', '-nv', '-O', download_path, download_url])
    proc.communicate()

    print('Extracting...')
    print(f'Root: {root_path}')

    proc = subprocess.Popen(['tar', '-xvzf', download_path, '-C', root_path])
    proc.communicate()
    exit()

if args.compress:
    if not (os.path.isdir(lib_destination_path) and os.path.isdir(include_destination_path)):
        print('ERROR: Dependencies directories do not exist at:')
        print(f'       {lib_destination_path}')
        print(f'       {include_destination_path}')
        print('  Run without --compress option to populate these directories first')
        exit(1)

    date = datetime.datetime.now().strftime('%Y-%m-%d')

    zip_filename = f'Dependencies_{date}.tar.gz'
    zip_filepath = os.path.join(scripts_path, zip_filename)

    if os.path.exists(zip_filepath):
        print('ERROR: Output file already exists at:')
        print(f'       {zip_filepath}')
        exit(1)

    print('Compressing...')
    print(f'Input:  {destination_path}')
    print(f'Output: {zip_filepath}')
    print(f'Root:   {root_path}')

    proc = subprocess.Popen(['tar', '-czvf', zip_filepath, '-C', root_path, os.path.basename(destination_path)])
    proc.communicate()

    resolved_deps_filepath_src = os.path.join(destination_path, 'dependencies.resolved')
    resolved_deps_filepath_dst = os.path.join(scripts_path, 'dependencies.resolved')
    shutil.copyfile(resolved_deps_filepath_src, resolved_deps_filepath_dst)

    print('Copied resolved dependencies to:')
    print(f'    {resolved_deps_filepath_dst}')

    exit()

if args.lipo:
    lib_source_paths = [os.path.join(lib_destination_path, arch) for arch in active_archs]

    if not all([os.path.isdir(source_path) for source_path in lib_source_paths]):
        print('ERROR: Dependencies need to be staged at:')
        for source_path in lib_source_paths:
            print(f'    {source_path}')
        exit(1)

    if not os.path.isdir(lib_destination_path):
        os.makedirs(lib_destination_path)

    source_path = lib_source_paths[0]
    filenames = [fn for fn in os.listdir(source_path) if fn.endswith('.dylib')]

    for filename in filenames:
        input_dylib_paths = [os.path.join(dest_path, filename) for dest_path in lib_source_paths]
        output_dylib_path = os.path.join(lib_destination_path, filename)

        if not all([os.path.exists(source_path) for source_path in input_dylib_paths]):
            print('ERROR: Matching arch dependencies not found:')
            for source_path in input_dylib_paths:
                source_path_state = '  [FOUND]' if os.path.exists(source_path) else '[MISSING]'
                print(f'    {source_path_state} {source_path}')
            exit(1)

        if os.path.exists(output_dylib_path):
            print('ERROR: Universal lib destination already exists:')
            print(f'    {output_dylib_path}')
            exit(1)

        lipo_cmd = ['lipo']
        lipo_cmd.extend(input_dylib_paths)
        lipo_cmd.append('-output')
        lipo_cmd.append(output_dylib_path)
        lipo_cmd.append('-create')

        print('Combining to create universal binary:')
        for source_path in input_dylib_paths:
            print(f'    {source_path}')
        print(f'    {output_dylib_path}')
        proc = subprocess.Popen(lipo_cmd)
        proc.communicate()

    exit()

os.makedirs(lib_destination_path)
os.makedirs(include_destination_path)

# Look for the dependency dylibs specified in dependencies.json
# This will fail immediately if any dependency cannot be found
for arch in active_archs:

    print(f'Dependency versions [{arch}]:')

    located_dependencies = []

    arch_search_paths = search_paths[arch]

    arch_lib_destination_path = os.path.join(lib_destination_path, arch)
    os.makedirs(arch_lib_destination_path)

    arch_include_destination_path = os.path.join(include_destination_path, arch)
    os.makedirs(arch_include_destination_path)

    for dependency, version in dependency_versions.items():

        print(f'  {dependency} @ {version}')

        dylib_name = f'{dependency}.{version}.dylib'

        located_dependency = locate_dependency(dylib_name, arch_search_paths)
        located_dependencies.append(located_dependency)

    # Process the dependencies as a set. With each dependency we process we may
    # discover new dependencies to add to the set.
    dylibs_to_process = set(located_dependencies)

    # After we've processed a dependency we can add it to these sets. Use these
    # to avoid potential recursive dependencies and assert that we only depend on
    # a single version of any particular library.
    processed_dylibs = set()
    libname_to_dylib_path = {}

    while len(dylibs_to_process):

        src_dylib_path = dylibs_to_process.pop()

        # Maintain the filename requested with this dependency
        dest_dylib_name = find_dylib_actual_name(src_dylib_path)

        src_dylib_path = os.path.realpath(src_dylib_path)

        if src_dylib_path in processed_dylibs:
            # print(f'Skipping previously handled dependency: {src_dylib_path}')
            continue

        # If this is a lib we've seen before, confirm that it's the same path as before
        previous_path = libname_to_dylib_path.get(dest_dylib_name, None)
        if previous_path and previous_path != src_dylib_path:
            print(f'ERROR: Mismatched library paths for {dylib_name}')
            print(f'  New: {src_dylib_path}')
            print(f'  Old: {previous_path}')
            exit(1)

        processed_dylibs.add(src_dylib_path)
        libname_to_dylib_path[dest_dylib_name] = src_dylib_path

        # Copy this dylib to local
        dest_dylib_path = os.path.join(arch_lib_destination_path, dest_dylib_name)
        dest_dylib_path = copy_dylib(src_dylib_path, dest_dylib_path)

        # print(f'Stamping -id into {dest_dylib_name}')
        stamp_dylib_id(dest_dylib_path)

        cmd = ['otool', '-L', dest_dylib_path]
        output = run_cmd(cmd)

        # Skip the first line, it just repeats the input dylib path
        # Skip the second line, it is the identity entry
        output = output[2:]

        output = [line for line in output if not is_system_library(line)]

        if output:
            print(f'Processing dependencies of {dest_dylib_name}:')

            for line in output:

                # line is like:
                #   @loader_path/../../../../opt/libsamplerate/lib/libsamplerate.0.dylib (compatibility version 3.0.0, current version 3.2.0)

                dependency_path = line.split(' (compatibility version')[0]
                dependency_dylib_name = os.path.split(dependency_path)[1]

                print(f'  Dependency {dependency_path}')
                # print(f'  Stamping -change for {dependency_dylib_name} into {dest_dylib_name}')
                stamp_dylib_change(dest_dylib_path, dependency_path)

                if dependency_path.startswith('@'):
                    dependency_path = locate_dependency(dependency_dylib_name, arch_search_paths)
                dylibs_to_process.add(dependency_path)

    for header_library in header_libraries:
        dylib_path = None
        for libname, libpath in libname_to_dylib_path.items():
            if libname.startswith(header_library):
                if dylib_path:
                    print(f'ERROR: More than one path for header library "{header_library}":')
                    print(f'  Old: {dylib_path}')
                    print(f'  New: {libpath}')
                    exit(1)
                else:
                    dylib_path = libpath

        if not dylib_path:
            print(f'ERROR: No path found for header library "{header_library}"')
            exit(1)

        # search for 'libxyz' and 'xyz'
        include_names = [header_library]
        if header_library.startswith('lib'):
            include_names.append(header_library[3:])

        # search for 'libxyz.h' and 'xyz.h'
        include_names.extend([f'{lib}.h' for lib in include_names])

        lib_path = os.path.dirname(os.path.dirname(dylib_path))
        src_include_path = None
        dest_include_path = None
        for include_name in include_names:
            include_path = os.path.join(lib_path, 'include', include_name)
            if os.path.exists(include_path):
                src_include_path = include_path
                dest_include_path = os.path.join(arch_include_destination_path, include_name)
                break
        if src_include_path:
            print(f'Copying includes from {src_include_path} to {dest_include_path}')
            if os.path.isfile(src_include_path):
                shutil.copyfile(src_include_path, dest_include_path)
            else:
                shutil.copytree(src_include_path, dest_include_path)
        else:
            print(f'ERROR: Include directory not found for {dylib_path}')
            exit(1)

    staged_txt_path = os.path.join(destination_path, f'dependencies.{arch}.resolved')
    with open(staged_txt_path, 'w') as text_file:
        for dylib_path in sorted(processed_dylibs):
            text_file.write(dylib_path)
            text_file.write(os.linesep)
    print(f'Staged dependency list: {staged_txt_path}')
