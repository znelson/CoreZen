#!/usr/bin/env python3

import os, sys, json, subprocess, pathlib, shutil

##
k_framework_extension = '.framework'
k_framework_separator = f'{k_framework_extension}{os.sep}'

EXTRACT_FRAMEWORK_DYLIB = True

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
def find_parent_framework_path(src_path):
	framework_path = None
	path = src_path
	while k_framework_separator in path:
		if not is_framework_path(path):
			path = os.path.dirname(path)
	if is_framework_path(path):
		framework_path = path
		if EXTRACT_FRAMEWORK_DYLIB:
			try:
				framework_lib_path = os.path.join(framework_path, 'Versions', 'Current', 'lib')
				filenames = os.listdir(framework_lib_path)
				filenames = [f for f in filenames if f.startswith('lib') and f.endswith('.dylib')]
				if len(filenames) > 1:
					raise ValueError(f'Too many .dylibs in framework: {filenames}')
				framework_path = os.path.join(framework_lib_path, filenames[0])
				print(f'EXTRACT_FRAMEWORK_DYLIB found: {framework_path}')
			except Exception as e:
				print(f'WARNING: Failed to extract framework dylib for {framework_path}: {e}')
	return framework_path

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
def parse_dylib_libname(path):
	path = path.strip()
	name = os.path.splitext(os.path.basename(path))[0]
	separators = {'-', '.'}
	# Candidate names, split on each separator
	dylib_names = [name.split(s) for s in separators]
	# Remove candidates that didn't have the separator
	dylib_names = [dn for dn in dylib_names if len(dn) > 1]
	# Remove candidates that didn't have a digit after the separator
	dylib_names = [dn for dn in dylib_names if dn[1][0].isdigit()]
	# Pull the name out of each split list
	dylib_names = [dn[0] for dn in dylib_names]
	if len(dylib_names) == 0:
		dylib_name = name
	else:
		# Go with the shortest name candidate
		dylib_name = min(dylib_names, key=len)
	return dylib_name

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
def make_dylib_stamp_name(path):
	stamp_name = os.path.split(path)[1]
	if is_framework_child_path(path):
		framework_path = find_parent_framework_path(path)
		if os.path.isdir(framework_path):
			parent_path = os.path.dirname(framework_path)
			stamp_name = path[len(parent_path)+1:]
			print(f'Corrected framework dylib stamp to: {stamp_name}')
		else:
			stamp_name = os.path.split(framework_path)[1]
			print(f'EXTRACT_FRAMEWORK_DYLIB corrected: {stamp_name}')
	return stamp_name

##
def stamp_dylib_id(path):
	stamp_name = make_dylib_stamp_name(path)
	cmd = [
		'install_name_tool',
		'-id',
		f'@rpath/{stamp_name}',
		path
	]
	run_cmd(cmd, validate_stderr=validate_install_name_tool_stderr)

##
def stamp_dylib_change(path, dependency_path):
	stamp_name = make_dylib_stamp_name(dependency_path)
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

		framework_src_path = find_parent_framework_path(src_path)

		if os.path.isdir(framework_src_path):

			framework_name = os.path.basename(framework_src_path)

			dest_dir = os.path.dirname(dest_path)
			framework_dest_path = os.path.join(dest_dir, framework_name)

			print(f'Copying framework {framework_src_path} to {framework_dest_path}')
			if os.path.exists(framework_dest_path):
				print('Destination framework already exists!')
				exit(1)
			shutil.copytree(framework_src_path, framework_dest_path, symlinks=True)

			relative_path = src_path[len(framework_src_path)+1:]
			dest_path = os.path.join(dest_dir, framework_name, relative_path)

			return dest_path

		else:
			src_path = framework_src_path
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

		else:
			print(f'  No file at {dylib_path}')
	
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

destination_path = os.path.abspath(os.path.join(scripts_path, '..', 'Dependencies'))

print(f'Scripts path: {scripts_path}')
print(f'Destination path: {destination_path}')

if os.path.exists(destination_path):
	print('Deleting existing Dependencies directory:')
	print(f'  {destination_path}')
	input('Press enter to continue...')
	shutil.rmtree(destination_path)

lib_destination_path = os.path.join(destination_path, 'lib')
include_destination_path = os.path.join(destination_path, 'include')

print(f'Libraries path: {lib_destination_path}')
print(f'Includes path: {include_destination_path}')

os.makedirs(lib_destination_path)
os.makedirs(include_destination_path)

print(f'Search paths:')
for search_path in search_paths:
	print(f'  {search_path}')

print('Dependency versions:')

located_dependencies = []

# Look for the dependency dylibs specified in dependencies.json
# This will fail immediately if any dependency cannot be found
for dependency, version in dependency_versions.items():

	print(f'  {dependency} @ {version}')

	dylib_name = f'{dependency}.{version}.dylib'

	located_dependency = locate_dependency(dylib_name, search_paths)
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
	dest_dylib_name = os.path.split(src_dylib_path)[1]

	src_dylib_path = os.path.realpath(src_dylib_path)

	if src_dylib_path in processed_dylibs:
		# print(f'Skipping previously handled dependency: {src_dylib_path}')
		continue

	dylib_libname = parse_dylib_libname(src_dylib_path)

	# If this is a lib we've seen before, confirm that it's the same path as before
	previous_path = libname_to_dylib_path.get(dylib_libname, None)
	if previous_path and previous_path != src_dylib_path:
		print(f'ERROR: Mismatched library paths for {dylib_name}')
		print(f'  New: {src_dylib_path}')
		print(f'  Old: {previous_path}')
		exit(1)

	processed_dylibs.add(src_dylib_path)
	libname_to_dylib_path[dylib_libname] = src_dylib_path

	# Copy this dylib to local
	dest_dylib_path = os.path.join(lib_destination_path, dest_dylib_name)
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

			dependency_path = line.split(' (compatibility version')[0]
			dependency_dylib_name = os.path.split(dependency_path)[1]

			if dependency_path.startswith('@'):
				dependency_path = locate_dependency(dependency_dylib_name, search_paths)

			print(f'  Dependency {dependency_path}')
			# print(f'  Stamping -change for {dependency_dylib_name} into {dest_dylib_name}')
			stamp_dylib_change(dest_dylib_path, dependency_path)
			dylibs_to_process.add(dependency_path)


for header_library in header_libraries:
	include_names = [header_library]
	if header_library.startswith('lib'):
		include_names.append(header_library[3:])
	dylib_path = libname_to_dylib_path[header_library]
	lib_path = os.path.dirname(os.path.dirname(dylib_path))
	src_include_path = None
	dest_include_path = None
	for include_name in include_names:
		include_path = os.path.join(lib_path, 'include', include_name)
		if os.path.exists(include_path):
			src_include_path = include_path
			dest_include_path = os.path.join(include_destination_path, include_name)
			break
	if src_include_path:
		print(f'Copying includes from {src_include_path} to {dest_include_path}')
		shutil.copytree(src_include_path, dest_include_path)
	else:
		print(f'ERROR: Include directory not found for {dylib_path}')
		exit(1)