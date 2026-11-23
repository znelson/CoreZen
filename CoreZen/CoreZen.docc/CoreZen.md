# ``CoreZen``

Store a domain model in SQLite, play and render media, and more, in a macOS app.

## Overview

CoreZen is an Objective-C framework for macOS 14 or later, on Apple silicon. It has three parts:

- term Persistence: A domain model stored in SQLite, with repositories that load, cache and save its objects asynchronously. It's built on [FMDB](https://github.com/ccgus/fmdb).
- term Media: Playback with [mpv](https://mpv.io), and frames rendered from video files with [FFmpeg](https://ffmpeg.org).
- term Utilities: Smaller AppKit and Foundation helpers, such as a tree of nodes, a preferences window and a work queue.

CoreZen's [README](https://github.com/znelson/CoreZen#readme) says how to get its dependencies and build it.

## Topics

### Essentials

- <doc:Persistence>
- <doc:Media>
- <doc:Utilities>

### Framework Version

- ``CoreZenVersionNumber``
- ``CoreZenVersionString``
