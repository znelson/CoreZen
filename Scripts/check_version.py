#!/usr/bin/env python3
"""
Check that CoreZen's version is the same everywhere it's written down.

The version is the CoreZen target's MARKETING_VERSION in CoreZen.xcodeproj,
which the framework reports as its CFBundleShortVersionString. CHANGELOG.md has a
section for each released version, newest first, below an Unreleased section for
changes since. A release is the commit tagged with its version, like v0.1.0.

Usage:
    ./check_version.py                 # Check the project's version is CHANGELOG.md's newest
    ./check_version.py --tag v0.1.0    # Also check a release tag names that version
    ./check_version.py --notes         # Print that version's CHANGELOG.md entry, after checking

CI runs it for every change, and with --tag when a version tag is pushed. It needs
only Python 3, including the one that comes with Xcode.
"""

import argparse
import datetime
import os
import re
import sys

ROOT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHANGELOG_PATH = os.path.join(ROOT_PATH, 'CHANGELOG.md')
PROJECT_PATH = os.path.join(ROOT_PATH, 'CoreZen.xcodeproj', 'project.pbxproj')

UNRELEASED_HEADING = 'Unreleased'
# A released version's heading, like "0.1.0 - 2026-11-19". Semantic Versioning
# doesn't allow leading zeros.
VERSION_HEADING = re.compile(r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*) - (\d{4}-\d{2}-\d{2})')
MARKETING_VERSION = re.compile(r'^\s*MARKETING_VERSION = "?([^";]*)"?;', re.MULTILINE)


##
def fail(message):
    print(f'check_version.py: {message}', file=sys.stderr)
    sys.exit(1)


##
def read(path):
    try:
        with open(path, encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        fail(f'{os.path.relpath(path, ROOT_PATH)} is missing')


##
def changelog_sections(text):
    """CHANGELOG.md's "## " sections, in order, as (heading, body) pairs."""
    sections = []
    for line in text.splitlines():
        if line.startswith('## '):
            sections.append((line[3:].strip(), []))
        elif sections:
            sections[-1][1].append(line)
    return [(heading, '\n'.join(body).strip()) for heading, body in sections]


##
def released_versions(sections):
    """
    The released versions in CHANGELOG.md, newest first, as (version, entry) pairs.
    Fails unless the first section is Unreleased and every other one is a version
    with a date and an entry, each older than the one above it.
    """
    if not sections or sections[0][0] != UNRELEASED_HEADING:
        fail(f'CHANGELOG.md should start with a "## {UNRELEASED_HEADING}" section, for changes not yet released')

    versions = []
    newer = None
    for heading, entry in sections[1:]:
        match = VERSION_HEADING.fullmatch(heading)
        if not match:
            fail(f'CHANGELOG.md has a heading "## {heading}", but a version\'s should look like "## 1.2.3 - 2026-01-31"')
        number = tuple(int(part) for part in match.group(1, 2, 3))
        version = '.'.join(match.group(1, 2, 3))
        try:
            date = datetime.date.fromisoformat(match.group(4))
        except ValueError:
            fail(f'CHANGELOG.md\'s heading "## {heading}" has a date that doesn\'t exist')
        if not entry:
            fail(f'CHANGELOG.md has no entry for {version}')
        if newer:
            newer_version, newer_number, newer_date = newer
            if number >= newer_number:
                fail(f'CHANGELOG.md lists {version} below {newer_version}; versions should go newest first')
            if date > newer_date:
                fail(f'CHANGELOG.md dates {version} after {newer_version}, which is listed above it')
        versions.append((version, entry))
        newer = (version, number, date)

    if not versions:
        fail('CHANGELOG.md has no released versions')
    return versions


##
def project_versions(text):
    """Every MARKETING_VERSION in the Xcode project, without repeats."""
    return sorted(set(MARKETING_VERSION.findall(text)))


##
def main():
    parser = argparse.ArgumentParser(description='Check that CoreZen\'s version is the same everywhere')
    parser.add_argument('--tag', help='a release tag that should name the version, like v0.1.0')
    parser.add_argument('--notes', action='store_true', help='print the version\'s CHANGELOG.md entry')
    args = parser.parse_args()

    version, entry = released_versions(changelog_sections(read(CHANGELOG_PATH)))[0]

    found = project_versions(read(PROJECT_PATH))
    if not found:
        fail('CoreZen.xcodeproj sets no MARKETING_VERSION')
    if found != [version]:
        fail(f'CoreZen.xcodeproj\'s MARKETING_VERSION is {", ".join(found)}, '
             f'but CHANGELOG.md\'s newest version is {version}')

    if args.tag is not None and args.tag != f'v{version}':
        fail(f'the tag is {args.tag}, but {version}\'s tag should be v{version}')

    if args.notes:
        print(entry)
    else:
        print(f'CoreZen {version}: CoreZen.xcodeproj and CHANGELOG.md agree')


if __name__ == '__main__':
    main()
