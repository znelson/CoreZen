# Changelog

Notable changes to CoreZen, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Until 1.0.0, a version that breaks the API raises the middle number, and any other version raises the last.

To note a change, add a line under Unreleased, in a group such as Added, Changed or Fixed. The README says how to release a version.

## Unreleased

### Added

- Documentation for the whole API, built with DocC: doc comments in the public headers, which Xcode shows in Quick Help, and an article with examples for each of CoreZen's three parts: persistence, media and utilities.
- `-[ZENFrameRenderer renderExactFrameAtSeconds:width:height:completion:]`, which renders the frame a player shows at a time, rather than the keyframe at or before it.

### Fixed

- Frames rendered from a file whose timestamps don't start at 0, such as an MPEG transport stream, come from the time asked for. Before, times counted from timestamp 0, so frames came from too early and their actual times were off by the file's start, and a rough seek could land a keyframe or more late.

## 0.1.0 - 2026-11-19

The first tagged version, with the persistence layer, media playback and frame rendering, and utilities that the README describes. Changes made before it are in the git history.
