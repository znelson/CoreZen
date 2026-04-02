#!/usr/bin/env python3
"""
Update project.pbxproj to match the current contents of Dependencies/lib and
Dependencies/include.

Automates the manual Xcode steps of removing and re-adding library and header
references after a dependency update (steps 10 and 11 of update_instructions.md).

Usage:
    ./update_project.py            # Update project.pbxproj
    ./update_project.py --dry-run  # Preview changes without writing
"""

import argparse
import hashlib
import json
import os
import re
import sys

LIB_GROUP_ID = '53D4B6342B51E38E00B91FA0'
INCLUDE_GROUP_ID = '53D4B5992B51E38E00B91FA0'
COPY_FILES_PHASE_ID = '5350F8BA2886178900F8CA68'
FRAMEWORKS_PHASE_ID = '5309C3A62885A1DC00BC0AAE'
FMDB_COPY_BF_ID = '5350F8BB2886179200F8CA68'
FMDB_FW_BF_ID = '538499112885FF21004ED6A1'


def generate_id(seed, used_ids):
    """Generate a deterministic 24-character hex ID, avoiding collisions."""
    n = 0
    while True:
        obj_id = hashlib.md5(f'{seed}#{n}'.encode()).hexdigest()[:24].upper()
        if obj_id not in used_ids:
            used_ids.add(obj_id)
            return obj_id
        n += 1


def quote_path(name):
    """Quote a path for pbxproj format if it contains special characters."""
    if re.search(r'[-+. @/]', name):
        return f'"{name}"'
    return name


def find_object_block(content, obj_id):
    """Find the start/end positions of an object definition block.

    Matches: \\t\\tID /* name */ = { ... };
    Returns (start, end) character positions, or (None, None) if not found.
    """
    def_pattern = rf'\t\t{obj_id}\s*/\*[^*]*\*/\s*=\s*\{{'
    m = re.search(def_pattern, content)
    if not m:
        return None, None
    start = m.start()
    end_m = re.search(r'\n\t\t\};\n', content[m.end():])
    if not end_m:
        return None, None
    return start, m.end() + end_m.end()


def find_list_ids(content, container_id, list_name):
    """Extract 24-char hex IDs from a named list within a container object."""
    start, end = find_object_block(content, container_id)
    if start is None:
        return []
    block = content[start:end]
    m = re.search(rf'{list_name}\s*=\s*\((.*?)\)\s*;', block, re.DOTALL)
    return re.findall(r'([0-9A-F]{24})', m.group(1)) if m else []


def find_build_file_ids(content, file_ref_ids):
    """Find PBXBuildFile IDs that reference the given file reference IDs."""
    result = []
    for fref in file_ref_ids:
        for m in re.finditer(
                rf'([0-9A-F]{{24}})\s*/\*[^*]*\*/\s*=\s*\{{'
                rf'isa = PBXBuildFile; fileRef = {fref}',
                content):
            result.append(m.group(1))
    return result


def remove_lines_by_id(content, ids_to_remove):
    """Remove top-level object lines (2-tab indent) that start with any of the given IDs."""
    for obj_id in ids_to_remove:
        content = re.sub(
            rf'^\t\t{obj_id}\b[^\n]*\n', '', content, flags=re.MULTILINE)
    return content


def remove_group_blocks(content, group_ids):
    """Remove multi-line PBXGroup blocks identified by their IDs."""
    for gid in group_ids:
        start, end = find_object_block(content, gid)
        if start is not None:
            content = content[:start] + content[end:]
    return content


def replace_list(content, container_id, list_name, entries_str):
    """Replace the contents of a named list within a container."""
    start, end = find_object_block(content, container_id)
    if start is None:
        print(f'WARNING: Object {container_id} not found')
        return content
    block = content[start:end]
    pattern = rf'({list_name}\s*=\s*\().*?(\)\s*;)'

    if not re.search(pattern, block, re.DOTALL):
        print(f'WARNING: {list_name} list not found in {container_id}')
        return content

    def replacer(m):
        return f'{m.group(1)}\n{entries_str}\t\t\t{m.group(2)}'

    new_block = re.sub(pattern, replacer, block, count=1, flags=re.DOTALL)
    return content[:start] + new_block + content[end:]


def insert_before(content, marker, text):
    """Insert text immediately before a marker string."""
    return content.replace(marker, text + marker)


def main():
    parser = argparse.ArgumentParser(
        description='Update project.pbxproj to match Dependencies/')
    parser.add_argument('--dry-run', action='store_true',
                        help='Preview changes without writing')
    args = parser.parse_args()

    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(scripts_dir)

    pbxproj_path = os.path.join(
        root_dir, 'CoreZen.xcodeproj', 'project.pbxproj')
    lib_dir = os.path.join(root_dir, 'Dependencies', 'lib')
    include_dir = os.path.join(root_dir, 'Dependencies', 'include')
    config_path = os.path.join(scripts_dir, 'dependencies.json')

    for path in [pbxproj_path, lib_dir, include_dir, config_path]:
        if not os.path.exists(path):
            print(f'ERROR: Not found: {path}')
            sys.exit(1)

    with open(config_path) as f:
        config = json.load(f)

    linked_libs = config.get('linked_libraries', [])
    if not linked_libs:
        print('WARNING: No "linked_libraries" in dependencies.json')
        print('  No libraries will be added to Link Binary with Libraries')

    # --- Scan filesystem ---

    dylibs = sorted(f for f in os.listdir(lib_dir) if f.endswith('.dylib'))
    if not dylibs:
        print('ERROR: No .dylib files found in Dependencies/lib/')
        sys.exit(1)

    header_dirs = {}
    for d in sorted(os.listdir(include_dir)):
        dp = os.path.join(include_dir, d)
        if os.path.isdir(dp):
            files = sorted(
                f for f in os.listdir(dp)
                if os.path.isfile(os.path.join(dp, f)))
            if files:
                header_dirs[d] = files

    print(f'Dependencies/lib:     {len(dylibs)} libraries')
    print(f'Dependencies/include: {len(header_dirs)} directories')

    # --- Read and parse project file ---

    with open(pbxproj_path) as f:
        content = f.read()

    all_ids = set(re.findall(r'\b([0-9A-F]{24})\b', content))

    old_lib_frefs = find_list_ids(content, LIB_GROUP_ID, 'children')
    old_inc_groups = find_list_ids(content, INCLUDE_GROUP_ID, 'children')

    old_hdr_frefs = []
    for gid in old_inc_groups:
        old_hdr_frefs.extend(find_list_ids(content, gid, 'children'))

    old_bf_ids = find_build_file_ids(content, old_lib_frefs)

    all_old = set(old_lib_frefs + old_inc_groups + old_hdr_frefs + old_bf_ids)

    print(f'\nRemoving:')
    print(f'  {len(old_lib_frefs)} library file refs')
    print(f'  {len(old_bf_ids)} build file entries')
    print(f'  {len(old_inc_groups)} header groups')
    print(f'  {len(old_hdr_frefs)} header file refs')

    # Remove old IDs from collision set so regeneration is deterministic
    all_ids -= all_old

    # --- Generate new IDs ---

    dylib_fref = {}
    dylib_copy_bf = {}
    dylib_link_bf = {}

    for name in dylibs:
        dylib_fref[name] = generate_id(f'fileref:lib/{name}', all_ids)
        dylib_copy_bf[name] = generate_id(f'buildfile:copy:{name}', all_ids)

        base = name.replace('.dylib', '')
        lib_name = base.rsplit('.', 1)[0] if '.' in base else base
        if lib_name in linked_libs:
            dylib_link_bf[name] = generate_id(
                f'buildfile:link:{name}', all_ids)

    inc_grp = {}
    hdr_fref = {}

    for dn, headers in header_dirs.items():
        inc_grp[dn] = generate_id(f'group:include/{dn}', all_ids)
        for h in headers:
            hdr_fref[(dn, h)] = generate_id(
                f'fileref:include/{dn}/{h}', all_ids)

    linked_names = sorted(dylib_link_bf.keys())

    print(f'\nAdding:')
    print(f'  {len(dylibs)} library file refs')
    print(f'  {len(dylibs)} Copy Files entries')
    print(f'  {len(linked_names)} Link Binary entries:')
    for name in linked_names:
        print(f'    {name}')
    print(f'  {len(inc_grp)} header groups')
    print(f'  {len(hdr_fref)} header file refs')

    if args.dry_run:
        print('\nDry run — no changes written.')
        return

    # --- Remove old entries ---

    content = remove_lines_by_id(
        content, old_bf_ids + old_lib_frefs + old_hdr_frefs)
    content = remove_group_blocks(content, old_inc_groups)

    # --- Add new PBXBuildFile entries ---

    bf_lines = []
    for name in dylibs:
        bf_lines.append(
            f'\t\t{dylib_copy_bf[name]} /* {name} in Copy Files */ = '
            f'{{isa = PBXBuildFile; fileRef = {dylib_fref[name]} '
            f'/* {name} */; settings = '
            f'{{ATTRIBUTES = (CodeSignOnCopy, ); }}; }};')
    for name in linked_names:
        bf_lines.append(
            f'\t\t{dylib_link_bf[name]} /* {name} in Frameworks */ = '
            f'{{isa = PBXBuildFile; fileRef = {dylib_fref[name]} '
            f'/* {name} */; }};')

    content = insert_before(
        content, '/* End PBXBuildFile section */',
        '\n'.join(bf_lines) + '\n')

    # --- Add new PBXFileReference entries ---

    fr_lines = []
    for name in dylibs:
        fr_lines.append(
            f'\t\t{dylib_fref[name]} /* {name} */ = '
            f'{{isa = PBXFileReference; '
            f'lastKnownFileType = "compiled.mach-o.dylib"; '
            f'path = {quote_path(name)}; sourceTree = "<group>"; }};')
    for (dn, h) in sorted(hdr_fref):
        fr_lines.append(
            f'\t\t{hdr_fref[(dn, h)]} /* {h} */ = '
            f'{{isa = PBXFileReference; '
            f'lastKnownFileType = sourcecode.c.h; '
            f'path = {h}; sourceTree = "<group>"; }};')

    content = insert_before(
        content, '/* End PBXFileReference section */',
        '\n'.join(fr_lines) + '\n')

    # --- Add new include PBXGroup blocks ---

    grp_blocks = []
    for dn in sorted(header_dirs):
        children = '\n'.join(
            f'\t\t\t\t{hdr_fref[(dn, h)]} /* {h} */,'
            for h in header_dirs[dn])
        grp_blocks.append(
            f'\t\t{inc_grp[dn]} /* {dn} */ = {{\n'
            f'\t\t\tisa = PBXGroup;\n'
            f'\t\t\tchildren = (\n'
            f'{children}\n'
            f'\t\t\t);\n'
            f'\t\t\tpath = {dn};\n'
            f'\t\t\tsourceTree = "<group>";\n'
            f'\t\t}};')

    content = insert_before(
        content, '/* End PBXGroup section */',
        '\n'.join(grp_blocks) + '\n')

    # --- Replace children/files lists ---

    lib_children = ''.join(
        f'\t\t\t\t{dylib_fref[n]} /* {n} */,\n' for n in dylibs)
    content = replace_list(content, LIB_GROUP_ID, 'children', lib_children)

    inc_children = ''.join(
        f'\t\t\t\t{inc_grp[dn]} /* {dn} */,\n'
        for dn in sorted(header_dirs))
    content = replace_list(
        content, INCLUDE_GROUP_ID, 'children', inc_children)

    copy_files = ''.join(
        f'\t\t\t\t{dylib_copy_bf[n]} /* {n} in Copy Files */,\n'
        for n in dylibs)
    copy_files += (
        f'\t\t\t\t{FMDB_COPY_BF_ID} /* FMDB.framework in Copy Files */,\n')
    content = replace_list(
        content, COPY_FILES_PHASE_ID, 'files', copy_files)

    fw_files = (
        f'\t\t\t\t{FMDB_FW_BF_ID} /* FMDB.framework in Frameworks */,\n')
    for name in linked_names:
        fw_files += (
            f'\t\t\t\t{dylib_link_bf[name]} '
            f'/* {name} in Frameworks */,\n')
    content = replace_list(
        content, FRAMEWORKS_PHASE_ID, 'files', fw_files)

    # --- Write ---

    with open(pbxproj_path, 'w') as f:
        f.write(content)

    print(f'\nUpdated: {pbxproj_path}')


if __name__ == '__main__':
    main()
