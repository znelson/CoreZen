#!/usr/bin/env python3
"""
Download a prebuilt copy of CoreZen's media dependencies into Dependencies/.

CI builds the dependencies with build_dependencies.py whenever what decides the
build changes (that script, build_dependencies.json or its patches) and
publishes the result as the GitHub release dependencies-<key>, where the key is
a hash of those files. This script computes the key for the current checkout and
downloads that release's archive, so what it installs always matches the pinned
sources. It needs only Python 3, including the one that comes with Xcode.

Usage:
    ./fetch_dependencies.py                  # Download into ../Dependencies, unless it's current
    ./fetch_dependencies.py --force          # Download even if Dependencies/ is current
    ./fetch_dependencies.py --archive FILE   # Install a local archive (with FILE.sha256 beside it)

Exits with status 2 when no release exists for the key: the dependencies changed
and CI hasn't published them yet. Build them with build_dependencies.py instead.
"""

import argparse
import os
import shutil
import sys
import tempfile
import urllib.error
import urllib.request

from build_dependencies import (ARCHIVE_ROOT, KEY_PREFIX, ROOT_PATH, dependencies_key, extract_tar, fail,
                                load_manifest, log, sha256_of)

DEFAULT_REPOSITORY = 'znelson/CoreZen'
ARCHIVE_NAME = 'Dependencies.tar.gz'
RELEASE_PREFIX = 'dependencies-'
EXIT_NOT_PUBLISHED = 2


##
def installed_key(output):
    """The key recorded in an installed Dependencies/, or None."""
    try:
        with open(os.path.join(output, 'dependencies.resolved')) as f:
            for line in f:
                if line.startswith(KEY_PREFIX):
                    return line[len(KEY_PREFIX):].strip()
    except FileNotFoundError:
        pass
    return None


##
def download(url, path):
    """Download url to path. Returns False if the server has no such file."""
    request = urllib.request.Request(url, headers={'User-Agent': 'CoreZen-fetch-dependencies'})
    try:
        with urllib.request.urlopen(request) as response, open(path, 'wb') as f:
            shutil.copyfileobj(response, f)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return False
        fail(f'Downloading {url} failed: {error}')
    return True


##
def read_checksum(path):
    """The SHA-256 from a file in shasum's format: '<hex>  <name>'."""
    with open(path) as f:
        fields = f.read().split()
    if not fields or len(fields[0]) != 64:
        fail(f'{path} doesn\'t hold a SHA-256')
    return fields[0].lower()


##
def checked_members(tar):
    """An archive's entries, if all are plain files or directories inside
    ARCHIVE_ROOT, with their modes reset so none can be left unreadable."""
    members = tar.getmembers()
    for member in members:
        parts = member.name.split('/')
        if parts[0] != ARCHIVE_ROOT or '..' in parts or not (member.isfile() or member.isdir()):
            fail(f'Unexpected entry in the archive: {member.name}')
        member.mode = 0o755 if member.isdir() or member.mode & 0o100 else 0o644
    return members


##
def install(archive, checksum, key, output):
    """Verify an archive and replace output with its contents."""
    actual = sha256_of(archive)
    if actual != checksum:
        fail(f'{archive} has SHA-256 {actual}, expected {checksum}')

    # Extract beside the output, so a failure leaves the current one in place
    staging = output + '.installing'
    shutil.rmtree(staging, ignore_errors=True)
    os.makedirs(staging)
    try:
        extract_tar(archive, staging, members=checked_members)
        extracted = os.path.join(staging, ARCHIVE_ROOT)
        found = installed_key(extracted)
        if found != key:
            fail(f'{archive} holds dependencies with key {found}, but this checkout needs {key}')
        shutil.rmtree(output, ignore_errors=True)
        os.rename(extracted, output)
    finally:
        shutil.rmtree(staging, ignore_errors=True)
    log(f'Installed dependencies {key} into {output}')


##
def main():
    parser = argparse.ArgumentParser(description='Download prebuilt CoreZen dependencies')
    parser.add_argument('--output', default=os.path.join(ROOT_PATH, 'Dependencies'),
                        help='Where to install lib/, include/ and dependencies.resolved')
    parser.add_argument('--repository', default=DEFAULT_REPOSITORY,
                        help='GitHub repository whose releases hold the archives (default: %(default)s)')
    parser.add_argument('--archive', metavar='FILE',
                        help='Install this archive, checked against FILE.sha256, instead of downloading')
    parser.add_argument('--force', action='store_true', help='Download even if the output is current')
    args = parser.parse_args()

    key = dependencies_key(load_manifest())
    output = os.path.abspath(args.output)

    if args.archive:
        install(args.archive, read_checksum(args.archive + '.sha256'), key, output)
        return

    if not args.force and installed_key(output) == key:
        log(f'{output} is up to date (dependencies {key})')
        return

    url = f'https://github.com/{args.repository}/releases/download/{RELEASE_PREFIX}{key}/{ARCHIVE_NAME}'
    with tempfile.TemporaryDirectory() as temporary:
        archive = os.path.join(temporary, ARCHIVE_NAME)
        log(f'Downloading {url}.sha256')
        if not download(url + '.sha256', archive + '.sha256'):
            relative = os.path.relpath(output, ROOT_PATH)
            print(f'No prebuilt dependencies are published for key {key}. From the repository root, build them with:\n'
                  f'    Scripts/build_dependencies.py --output {output if relative.startswith("..") else relative}',
                  file=sys.stderr, flush=True)
            sys.exit(EXIT_NOT_PUBLISHED)
        log(f'Downloading {url}')
        if not download(url, archive):
            fail(f'{url} is missing, though its .sha256 is published')
        install(archive, read_checksum(archive + '.sha256'), key, output)


if __name__ == '__main__':
    main()
