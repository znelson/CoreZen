#!/usr/bin/env python3
"""
Summarize how much of CoreZen the tests run, from an xcodebuild result bundle.

While code coverage is on, xcodebuild test records which lines of
CoreZen.framework the tests ran. This prints the share of lines they ran, then
each file's, starting with the files that have the most lines left unrun, as
Markdown. CI adds it to the summary page of each run.

Usage:
    xcodebuild test -scheme CoreZen -project CoreZen.xcodeproj -resultBundlePath build/Tests.xcresult
    ./coverage_report.py build/Tests.xcresult

It needs Xcode, for xccov, and Python 3, including the one that comes with Xcode.
"""

import argparse
import json
import os
import subprocess
import sys

ROOT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_NAME = 'CoreZen.framework'


##
def fail(message):
    print(f'coverage_report.py: {message}', file=sys.stderr)
    sys.exit(1)


##
def coverage_report(result_bundle):
    """xccov's coverage report for a result bundle, as JSON."""
    try:
        result = subprocess.run(['xcrun', 'xccov', 'view', '--report', '--json', result_bundle],
                                capture_output=True, text=True)
    except FileNotFoundError:
        fail('xcrun is missing; this needs Xcode')
    if result.returncode != 0:
        fail(f'xccov couldn\'t read {result_bundle}: {result.stderr.strip()}')
    return json.loads(result.stdout)


##
def percent(covered, total):
    """covered of total as a percentage, never rounded up to 100% unless it's all of them."""
    if total == 0:
        return '-'
    value = 100 * covered / total
    if covered < total:
        value = min(value, 99.9)
    return f'{value:.1f}%'


##
def markdown(target):
    """The report for one target, in Markdown."""
    covered, total = target['coveredLines'], target['executableLines']
    lines = [
        '### Code coverage',
        '',
        f'The tests ran **{percent(covered, total)}** of {TARGET_NAME}\'s lines: {covered:,} of {total:,}.',
        '',
        '<details><summary>By file, most lines not run first</summary>',
        '',
        '| File | Lines run | Lines not run |',
        '| --- | ---: | ---: |',
    ]
    files = sorted(target['files'],
                   key=lambda f: (f['coveredLines'] - f['executableLines'], os.path.relpath(f['path'], ROOT_PATH)))
    for f in files:
        not_run = f['executableLines'] - f['coveredLines']
        lines.append(f'| `{os.path.relpath(f["path"], ROOT_PATH)}` '
                     f'| {percent(f["coveredLines"], f["executableLines"])} | {not_run:,} |')
    lines += ['', '</details>']
    return '\n'.join(lines)


##
def main():
    parser = argparse.ArgumentParser(description='Summarize how much of CoreZen the tests run')
    parser.add_argument('result_bundle', help='the .xcresult bundle from xcodebuild test')
    args = parser.parse_args()

    if not os.path.isdir(args.result_bundle):
        fail(f'{args.result_bundle} isn\'t a result bundle')
    report = coverage_report(args.result_bundle)
    target = next((t for t in report.get('targets', []) if t['name'] == TARGET_NAME), None)
    if target is None:
        fail(f'{args.result_bundle} has no coverage for {TARGET_NAME}; was code coverage off?')
    print(markdown(target))


if __name__ == '__main__':
    main()
