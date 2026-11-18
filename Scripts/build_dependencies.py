#!/usr/bin/env python3
"""
Build CoreZen's media dependencies (FFmpeg, libmpv and the libraries they need)
from pinned sources, for Apple silicon and a fixed minimum macOS.

Everything comes from build_dependencies.json: the source of each package
(a URL plus SHA-256, or a git tag plus commit), its build options, the macOS
deployment target, and pinned versions of the build tools. The builds are
LGPL and decode-only: no encoders, network protocols or GPL components.

Only Xcode (or its command line tools), git and Python 3.10 or later need to be
installed. Xcode's own python3 is 3.9, which is too old for the pinned meson
and pkgconf. The script creates its own virtual environment with meson, ninja,
pkgconf and jinja2, and keeps Homebrew out of the build: PATH excludes
/opt/homebrew, and pkg-config only sees libraries built here.

Usage:
    ./build_dependencies.py                     # Build everything, stage into build/dependencies/output
    ./build_dependencies.py --output ../Dependencies
    ./build_dependencies.py --only mpv          # Rebuild one package (its dependencies must be built)
    ./build_dependencies.py --clean             # Start from scratch
    ./build_dependencies.py --archive FILE      # Also pack the output into FILE (.tar.gz) and FILE.sha256
    ./build_dependencies.py --print-key         # Print the key prebuilt archives are published under

The output matches the layout of Dependencies/: lib/ holds the dylibs, with
install names under @rpath and ad-hoc signatures, include/ holds the headers,
licenses/ holds each package's license files (and the patches CoreZen applies)
with a summary in NOTICES.md, and dependencies.resolved lists what was built
and from which source. CoreZen.framework bundles licenses/ as a resource.

The key is a hash of this script, build_dependencies.json and its patches:
everything that decides what the build produces. CI publishes each archive it
builds as the GitHub release dependencies-<key>, which fetch_dependencies.py
downloads.
"""

import argparse
import gzip
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import urllib.request

SCRIPTS_PATH = os.path.dirname(os.path.abspath(__file__))
ROOT_PATH = os.path.dirname(SCRIPTS_PATH)
MANIFEST_PATH = os.path.join(SCRIPTS_PATH, 'build_dependencies.json')
WORK_PATH = os.path.join(ROOT_PATH, 'build', 'dependencies')
# Top-level directory inside an archive, which extracts in place of Dependencies/
ARCHIVE_ROOT = 'Dependencies'
KEY_PREFIX = '# Key: '
# The pinned meson and pkgconf need this. fetch_dependencies.py, which imports
# this script but doesn't build, works with older versions.
MINIMUM_BUILD_PYTHON = (3, 10)


##
def log(message):
    print(message, flush=True)


##
def fail(message):
    print(f'ERROR: {message}', file=sys.stderr, flush=True)
    sys.exit(1)


##
def run(cmd, env=None, cwd=None, log_path=None):
    """Run a command. With log_path, write its output there and show the end on failure."""
    if log_path:
        with open(log_path, 'a') as log_file:
            log_file.write(f'\n$ {" ".join(cmd)}\n')
            log_file.flush()
            result = subprocess.run(cmd, env=env, cwd=cwd, stdout=log_file, stderr=subprocess.STDOUT)
        if result.returncode != 0:
            with open(log_path) as log_file:
                tail = log_file.readlines()[-40:]
            fail(f'{cmd[0]} failed ({result.returncode}), last lines of {log_path}:\n' + ''.join(tail))
        return ''
    result = subprocess.run(cmd, env=env, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        fail(f'{" ".join(cmd)} failed ({result.returncode}):\n{result.stderr}')
    return result.stdout


##
def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


##
def load_manifest():
    with open(MANIFEST_PATH) as f:
        return json.load(f)


##
def dependencies_key(manifest):
    """A short hash of everything that decides what the build produces: this
    script, the manifest and the patches it lists. Changing any of them changes
    the key, so a prebuilt archive can never be mistaken for a different build."""
    paths = [os.path.abspath(__file__), MANIFEST_PATH]
    for package in manifest['packages']:
        paths += [os.path.join(SCRIPTS_PATH, patch) for patch in package.get('patches', [])]
    digest = hashlib.sha256()
    for path in paths:
        with open(path, 'rb') as f:
            content = f.read()
        digest.update(f'{os.path.relpath(path, SCRIPTS_PATH)}\0{len(content)}\0'.encode())
        digest.update(content)
    return digest.hexdigest()[:16]


##
def extract_tar(archive, destination, members=None):
    """Extract a tar archive into destination. Uses tarfile's 'data' filter, which
    refuses absolute paths, links that leave the destination and special files,
    where Python has it. Xcode's Python 3.9.6 is older than the filter, so callers
    must only pass archives they've verified."""
    with tarfile.open(archive) as tar:
        if hasattr(tarfile, 'data_filter'):
            tar.extractall(destination, members=members(tar) if members else None, filter='data')
        else:
            tar.extractall(destination, members=members(tar) if members else None)


##
def write_archive(output, archive):
    """Pack a staged output directory into archive (.tar.gz), under ARCHIVE_ROOT,
    and write archive.sha256 beside it. Entries are sorted and carry no times or
    owners, so the same files always make the same archive."""
    entries = []
    for directory, subdirectories, files in os.walk(output):
        for name in subdirectories + files:
            entries.append(os.path.relpath(os.path.join(directory, name), output))

    os.makedirs(os.path.dirname(os.path.abspath(archive)), exist_ok=True)
    with open(archive, 'wb') as raw, \
            gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as compressed, \
            tarfile.open(fileobj=compressed, mode='w', format=tarfile.PAX_FORMAT) as tar:
        for relative in ['.'] + sorted(entries):
            path = os.path.join(output, relative)
            info = tar.gettarinfo(path, arcname=os.path.normpath(os.path.join(ARCHIVE_ROOT, relative)))
            if not (info.isfile() or info.isdir()):
                fail(f'Can only archive files and directories: {path}')
            info.mtime = 0
            info.uid = info.gid = 0
            info.uname = info.gname = ''
            info.mode = 0o755 if info.isdir() or os.access(path, os.X_OK) else 0o644
            if info.isfile():
                with open(path, 'rb') as f:
                    tar.addfile(info, f)
            else:
                tar.addfile(info)

    with open(archive + '.sha256', 'w') as f:
        f.write(f'{sha256_of(archive)}  {os.path.basename(archive)}\n')
    log(f'Wrote {archive} ({os.path.getsize(archive) / 1048576:.1f} MB) and its .sha256')


##
class Builder:
    def __init__(self, manifest, args):
        self.manifest = manifest
        self.args = args
        self.target = manifest['macos_deployment_target']
        self.arch = manifest['arch']
        self.downloads = os.path.join(WORK_PATH, 'downloads')
        self.sources = os.path.join(WORK_PATH, 'src')
        self.builds = os.path.join(WORK_PATH, 'build')
        self.logs = os.path.join(WORK_PATH, 'logs')
        self.prefix = os.path.join(WORK_PATH, 'prefix')
        self.venv = os.path.join(WORK_PATH, 'venv')
        self.jobs = str(args.jobs or os.cpu_count() or 4)

    # --- Environment ---

    def setup_tools(self):
        """Create the virtual environment with the pinned build tools."""
        tools = self.manifest['build_tools']
        stamp = os.path.join(self.venv, 'build_tools.json')
        if os.path.exists(stamp):
            with open(stamp) as f:
                if json.load(f) == tools:
                    return
            shutil.rmtree(self.venv)
        log(f'Creating build tools environment: {", ".join(tools)}')
        run([sys.executable, '-m', 'venv', self.venv])
        run([os.path.join(self.venv, 'bin', 'pip'), 'install', '--quiet', '--disable-pip-version-check'] + tools)
        with open(stamp, 'w') as f:
            json.dump(tools, f)

    def setup_environment(self):
        sdk = run(['xcrun', '--sdk', 'macosx', '--show-sdk-path']).strip()
        clang = run(['xcrun', '--sdk', 'macosx', '--find', 'clang']).strip()
        clangxx = run(['xcrun', '--sdk', 'macosx', '--find', 'clang++']).strip()
        flags = f'-arch {self.arch} -mmacosx-version-min={self.target} -isysroot {sdk}'
        pkgconfig_path = os.path.join(self.prefix, 'lib', 'pkgconfig')

        env = {
            'HOME': os.environ.get('HOME', ''),
            'TMPDIR': os.environ.get('TMPDIR', '/tmp'),
            'LANG': 'C',
            'LC_ALL': 'C',
            # The venv's tools first, then only system paths: nothing from Homebrew
            'PATH': f'{os.path.join(self.venv, "bin")}:/usr/bin:/bin:/usr/sbin:/sbin',
            'DEVELOPER_DIR': run(['xcode-select', '-p']).strip(),
            'SDKROOT': sdk,
            'MACOSX_DEPLOYMENT_TARGET': self.target,
            'CC': clang,
            'CXX': clangxx,
            'OBJC': clang,
            'CFLAGS': f'{flags} -O2',
            'CXXFLAGS': f'{flags} -O2',
            'OBJCFLAGS': f'{flags} -O2',
            # Leave room in each library to rewrite its install names to @rpath
            'LDFLAGS': f'{flags} -Wl,-headerpad_max_install_names',
            'PKG_CONFIG': os.path.join(self.venv, 'bin', 'pkgconf'),
            'PKG_CONFIG_PATH': pkgconfig_path,
            'PKG_CONFIG_LIBDIR': pkgconfig_path,
        }
        self.env = env
        self.sdk = sdk
        self.clang = clang

    # --- Sources ---

    def patches(self, package):
        """A package's patch files (paths relative to Scripts/) with their SHA-256s."""
        result = {}
        for patch in package.get('patches', []):
            path = os.path.join(SCRIPTS_PATH, patch)
            if not os.path.isfile(path):
                fail(f'{package["name"]}: missing patch {path}')
            result[patch] = sha256_of(path)
        return result

    def apply_patches(self, package, source_dir):
        for patch in package.get('patches', []):
            log(f'  Applying {patch}')
            run(['patch', '-p1', '--forward', '--silent', '--input', os.path.join(SCRIPTS_PATH, patch)],
                cwd=source_dir)

    def fetch(self, package):
        """Download or clone a package's source, verify it and apply its patches.
        Returns the source directory."""
        name = package['name']
        source_dir = os.path.join(self.sources, f'{name}-{package["version"]}')
        # Records which source and patches the directory holds, so a changed
        # pin or patch gets a fresh copy
        identity = {key: package.get(key) for key in ('url', 'sha256', 'git', 'tag', 'commit')}
        identity['patches'] = self.patches(package)
        marker = os.path.join(source_dir, '.corezen-source.json')
        if os.path.isdir(source_dir):
            if os.path.exists(marker):
                with open(marker) as f:
                    if json.load(f) == identity:
                        return source_dir
            shutil.rmtree(source_dir)

        if 'git' in package:
            log(f'  Cloning {package["git"]} at {package["tag"]}')
            run(['git', 'clone', '--quiet', '--depth', '1', '--branch', package['tag'],
                 '--recurse-submodules', '--shallow-submodules', package['git'], source_dir])
            commit = run(['git', '-C', source_dir, 'rev-parse', 'HEAD']).strip()
            if commit != package['commit']:
                shutil.rmtree(source_dir)
                fail(f'{name}: tag {package["tag"]} is commit {commit}, expected {package["commit"]}')
            self.apply_patches(package, source_dir)
            with open(marker, 'w') as f:
                json.dump(identity, f)
            return source_dir

        url = package['url']
        archive = os.path.join(self.downloads, os.path.basename(url))
        if not os.path.exists(archive) or sha256_of(archive) != package['sha256']:
            log(f'  Downloading {url}')
            request = urllib.request.Request(url, headers={'User-Agent': 'CoreZen-build-dependencies'})
            with urllib.request.urlopen(request) as response, open(archive, 'wb') as f:
                shutil.copyfileobj(response, f)
        actual = sha256_of(archive)
        if actual != package['sha256']:
            os.remove(archive)
            fail(f'{name}: {os.path.basename(archive)} has SHA-256 {actual}, expected {package["sha256"]}')

        # Extract only after the checksum matches, into a fresh directory
        staging = source_dir + '.extracting'
        shutil.rmtree(staging, ignore_errors=True)
        os.makedirs(staging)
        extract_tar(archive, staging)
        entries = os.listdir(staging)
        if len(entries) != 1:
            fail(f'{name}: expected one top-level directory in {archive}, found {entries}')
        self.apply_patches(package, os.path.join(staging, entries[0]))
        os.rename(os.path.join(staging, entries[0]), source_dir)
        os.rmdir(staging)
        with open(marker, 'w') as f:
            json.dump(identity, f)
        return source_dir

    # --- Builds ---

    def build(self, package):
        name = package['name']
        build_dir = os.path.join(self.builds, name)
        stamp = os.path.join(build_dir, '.built')
        # Fields that don't change what gets built, so editing them only restages
        built_from = {k: v for k, v in package.items() if k not in ('notes', 'license', 'license_files', 'credit')}
        stamp_data = {'package': built_from, 'patches': self.patches(package)}
        if os.path.exists(stamp) and name not in self.args.only:
            with open(stamp) as f:
                if json.load(f) == stamp_data:
                    log(f'{name} {package["version"]}: up to date')
                    return

        log(f'{name} {package["version"]}')
        source_dir = self.fetch(package)
        shutil.rmtree(build_dir, ignore_errors=True)
        os.makedirs(build_dir)
        log_path = os.path.join(self.logs, f'{name}.log')
        if os.path.exists(log_path):
            os.remove(log_path)

        log(f'  Building (log: {os.path.relpath(log_path, ROOT_PATH)})')
        if package['build'] == 'meson':
            self.build_meson(package, source_dir, build_dir, log_path)
        elif package['build'] == 'ffmpeg':
            self.build_ffmpeg(package, source_dir, build_dir, log_path)
        else:
            fail(f'{name}: unknown build type {package["build"]}')

        with open(stamp, 'w') as f:
            json.dump(stamp_data, f)

    def build_meson(self, package, source_dir, build_dir, log_path):
        meson = os.path.join(self.venv, 'bin', 'meson')
        run([meson, 'setup', build_dir, source_dir,
             f'--prefix={self.prefix}', '--libdir=lib', '--buildtype=release',
             '-Ddefault_library=shared', '-Db_ndebug=true',
             # Never download missing dependencies as meson subprojects
             '--wrap-mode=nofallback'] + package['options'],
            env=self.env, log_path=log_path)
        run([meson, 'compile', '-C', build_dir, '-j', self.jobs], env=self.env, log_path=log_path)
        run([meson, 'install', '-C', build_dir], env=self.env, log_path=log_path)

    def build_ffmpeg(self, package, source_dir, build_dir, log_path):
        env = self.env
        run([os.path.join(source_dir, 'configure'),
             f'--prefix={self.prefix}', f'--cc={env["CC"]}', f'--cxx={env["CXX"]}',
             f'--arch={self.arch}', '--target-os=darwin', f'--pkg-config={env["PKG_CONFIG"]}',
             f'--extra-cflags={env["CFLAGS"]}', f'--extra-ldflags={env["LDFLAGS"]}'] + package['options'],
            env=env, cwd=build_dir, log_path=log_path)
        run(['make', f'-j{self.jobs}'], env=env, cwd=build_dir, log_path=log_path)
        run(['make', 'install'], env=env, cwd=build_dir, log_path=log_path)

    # --- Staging ---

    def dependencies_of(self, dylib):
        """Install names a dylib links against, excluding its own ID."""
        lines = run(['otool', '-L', dylib]).splitlines()[1:]
        names = [line.strip().split(' (compatibility version')[0] for line in lines]
        own_id = run(['otool', '-D', dylib]).splitlines()[-1].strip()
        return [n for n in names if n != own_id]

    def prefix_library(self, install_name):
        """Path in the prefix for an install name that points into it, else None."""
        prefix_lib = os.path.join(self.prefix, 'lib')
        if install_name.startswith(prefix_lib + '/'):
            return install_name
        if install_name.startswith('@rpath/'):
            path = os.path.join(prefix_lib, os.path.basename(install_name))
            return path if os.path.exists(path) else None
        return None

    def stage(self, output):
        lib_out = os.path.join(output, 'lib')
        include_out = os.path.join(output, 'include')
        shutil.rmtree(output, ignore_errors=True)
        os.makedirs(lib_out)
        os.makedirs(include_out)

        # Collect the libraries CoreZen links and everything they link from the prefix
        prefix_lib = os.path.join(self.prefix, 'lib')
        pending = []
        for library in self.manifest['stage']['libraries']:
            matches = sorted(f for f in os.listdir(prefix_lib)
                             if f.startswith(library + '.') and f.endswith('.dylib') and f.count('.') == 2)
            if len(matches) != 1:
                fail(f'Expected one {library}.<major>.dylib in {prefix_lib}, found {matches}')
            pending.append(os.path.join(prefix_lib, matches[0]))

        staged = {}
        while pending:
            path = pending.pop()
            name = os.path.basename(path)
            if name in staged:
                continue
            staged[name] = path
            for dependency in self.dependencies_of(path):
                found = self.prefix_library(dependency)
                if found:
                    pending.append(found)

        for name, path in sorted(staged.items()):
            destination = os.path.join(lib_out, name)
            shutil.copyfile(os.path.realpath(path), destination)
            os.chmod(destination, 0o755)
            changes = []
            for dependency in self.dependencies_of(destination):
                found = self.prefix_library(dependency)
                if found:
                    changes += ['-change', dependency, f'@rpath/{os.path.basename(found)}']
            run(['install_name_tool', '-id', f'@rpath/{name}'] + changes + [destination])
            # Rewriting install names invalidates the linker's ad-hoc signature
            run(['codesign', '--force', '--sign', '-', destination])

        self.verify(lib_out, staged)

        for header in self.manifest['stage']['headers']:
            source = os.path.join(self.prefix, 'include', header)
            if not os.path.isdir(source):
                fail(f'Missing headers: {source}')
            shutil.copytree(source, os.path.join(include_out, header))

        with open(os.path.join(output, 'dependencies.resolved'), 'w') as f:
            f.write(f'# Built by Scripts/build_dependencies.py for {self.arch}, macOS {self.target}+\n')
            f.write(f'{KEY_PREFIX}{dependencies_key(self.manifest)}\n')
            f.write(f'# SDK: {os.path.basename(self.sdk)}\n')
            for package in self.manifest['packages']:
                source = (f'{package["git"]} {package["tag"]} {package["commit"]}'
                          if 'git' in package else f'{package["url"]} sha256:{package["sha256"]}')
                f.write(f'{package["name"]} {package["version"]} {source}\n')
                for patch, digest in self.patches(package).items():
                    f.write(f'    patch {patch} sha256:{digest}\n')
            f.write('# Staged libraries:\n')
            for name in sorted(staged):
                f.write(f'{name}\n')

        self.stage_licenses(os.path.join(output, 'licenses'))

        size = sum(os.path.getsize(os.path.join(lib_out, n)) for n in staged)
        log(f'Staged {len(staged)} libraries ({size / 1048576:.1f} MB) into {output}')

    def stage_licenses(self, licenses_out):
        """Copy each package's license files, and the patches CoreZen applies to it,
        into a folder named for the package, and summarize them in NOTICES.md.
        CoreZen.framework bundles the whole folder, so apps ship it along with the
        libraries."""
        packages = self.manifest['packages']
        os.makedirs(licenses_out)
        for package in packages:
            for field in ('license', 'license_files'):
                if not package.get(field):
                    fail(f'{package["name"]}: no {field} in {os.path.basename(MANIFEST_PATH)}')
            source_dir = self.fetch(package)
            package_out = os.path.join(licenses_out, package['name'])
            for relative in package['license_files']:
                source = os.path.join(source_dir, relative)
                if not os.path.isfile(source):
                    fail(f'{package["name"]}: missing license file {relative}')
                destination = os.path.join(package_out, relative)
                os.makedirs(os.path.dirname(destination), exist_ok=True)
                shutil.copyfile(source, destination)
            for patch in package.get('patches', []):
                destination = os.path.join(package_out, 'patches', os.path.basename(patch))
                os.makedirs(os.path.dirname(destination), exist_ok=True)
                shutil.copyfile(os.path.join(SCRIPTS_PATH, patch), destination)

        def source_of(package):
            if 'git' in package:
                return f'{package["git"]} at {package["tag"]} ({package["commit"]})'
            return package['url']

        lgpl = [p['name'] for p in packages if p['license'].startswith('LGPL')]
        patched = [p for p in packages if p.get('patches')]
        credits = [p['credit'] for p in packages if p.get('credit')]
        lines = [
            '# Third-party libraries in CoreZen',
            '',
            'CoreZen.framework contains these libraries, built from source for '
            f'{self.arch} and macOS {self.target} or later by CoreZen\'s Scripts/build_dependencies.py. '
            'The folder named for each one holds its license texts.',
            '',
            '| Library | Version | License | Source |',
            '|---|---|---|---|',
        ]
        lines += [f'| {p["name"]} | {p["version"]} | {p["license"]} | {source_of(p)} |' for p in packages]
        if lgpl:
            lines += [
                '',
                '## LGPL libraries',
                '',
                (lgpl[0] + ' is' if len(lgpl) == 1 else f'{", ".join(lgpl[:-1])} and {lgpl[-1]} are') +
                ' licensed under the GNU Lesser General Public License, version 2.1 or later. '
                'CoreZen.framework links them as separate dynamic libraries, in its Frameworks folder, '
                'so they can be replaced with modified versions. Their source code is at the addresses above.',
            ]
            for package in patched:
                names = ', '.join(os.path.basename(patch) for patch in package['patches'])
                lines += ['', f'CoreZen changes {package["name"]} with these patches, in its patches folder: {names}.']
        if credits:
            lines += ['', '## Credits', ''] + credits
        with open(os.path.join(licenses_out, 'NOTICES.md'), 'w') as f:
            f.write('\n'.join(lines) + '\n')

    def verify(self, lib_out, staged):
        """Every staged library must be arm64 only, built for the deployment target,
        and link only other staged libraries or the system."""
        problems = []
        for name in sorted(staged):
            path = os.path.join(lib_out, name)
            archs = run(['lipo', '-archs', path]).split()
            if archs != [self.arch]:
                problems.append(f'{name}: architectures {archs}')
            build = run(['vtool', '-show-build', path])
            minos = next((line.split()[1] for line in build.splitlines() if line.strip().startswith('minos')), None)
            if minos != self.target:
                problems.append(f'{name}: minimum macOS {minos}')
            for dependency in self.dependencies_of(path):
                if dependency.startswith('@rpath/'):
                    if os.path.basename(dependency) not in staged:
                        problems.append(f'{name}: links {dependency}, which is not staged')
                elif not dependency.startswith(('/usr/lib/', '/System/')):
                    problems.append(f'{name}: links {dependency}')
        if problems:
            fail('Staged libraries failed verification:\n  ' + '\n  '.join(problems))


##
def main():
    parser = argparse.ArgumentParser(description='Build CoreZen dependencies from pinned sources')
    parser.add_argument('--output', default=os.path.join(WORK_PATH, 'output'),
                        help='Where to stage lib/, include/ and dependencies.resolved')
    parser.add_argument('--only', action='append', default=[], metavar='PACKAGE',
                        help='Rebuild only this package (repeatable)')
    parser.add_argument('--clean', action='store_true', help='Delete previous downloads and builds first')
    parser.add_argument('--jobs', type=int, help='Parallel build jobs (default: number of CPUs)')
    parser.add_argument('--archive', metavar='FILE',
                        help='Also pack the output into FILE (.tar.gz), with its SHA-256 in FILE.sha256')
    parser.add_argument('--print-key', action='store_true',
                        help='Print the key prebuilt archives are published under, and exit')
    args = parser.parse_args()

    manifest = load_manifest()
    if args.print_key:
        print(dependencies_key(manifest))
        return

    if sys.version_info < MINIMUM_BUILD_PYTHON:
        fail(f'Building needs Python {".".join(map(str, MINIMUM_BUILD_PYTHON))} or later, for meson and pkgconf, '
             f'but {sys.executable} is Python {sys.version.split()[0]}. Xcode\'s python3 is too old: install a '
             'newer one, from python.org or Homebrew. (Scripts/fetch_dependencies.py works with Xcode\'s.)')

    names = [p['name'] for p in manifest['packages']]
    for name in args.only:
        if name not in names:
            fail(f'Unknown package {name}; choose from {", ".join(names)}')

    if args.clean:
        shutil.rmtree(WORK_PATH, ignore_errors=True)

    builder = Builder(manifest, args)
    for directory in (builder.downloads, builder.sources, builder.builds, builder.logs, builder.prefix):
        os.makedirs(directory, exist_ok=True)

    builder.setup_tools()
    builder.setup_environment()
    log(f'Building for {manifest["arch"]}, macOS {manifest["macos_deployment_target"]}+, '
        f'with {os.path.basename(builder.sdk)}')

    for package in manifest['packages']:
        if not args.only or package['name'] in args.only:
            builder.build(package)

    output = os.path.abspath(args.output)
    builder.stage(output)
    if args.archive:
        write_archive(output, args.archive)


if __name__ == '__main__':
    main()
