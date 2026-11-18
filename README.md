# CoreZen.framework

[![Xcode - Build and Analyze](https://github.com/znelson/CoreZen/actions/workflows/objective-c-xcode.yml/badge.svg?branch=main)](https://github.com/znelson/CoreZen/actions/workflows/objective-c-xcode.yml)

A macOS Cocoa framework made up of useful bits of code from my side projects.

Written by [Zach Nelson](https://github.com/znelson). See the [LICENSE file](https://github.com/znelson/CoreZen/blob/main/LICENSE) for license info (it's the MIT license).

## Getting Started

`CoreZen` runs on macOS 14 or later, on Apple silicon only.

### FMDB Dependency
`CoreZen` uses [FMDB](https://github.com/ccgus/fmdb) through Swift Package Manager and links it into `CoreZen.framework`. Xcode fetches it automatically; the exact version is pinned in `CoreZen.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

_**Installation:**_ Nothing to install. To fetch it ahead of a build, run `xcodebuild -resolvePackageDependencies -project CoreZen.xcodeproj -scheme CoreZen`.

### mpv and FFmpeg Dependencies
`CoreZen` links against and bundles dynamic libraries for [libmpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/libmpv.rst) and [FFmpeg](https://ffmpeg.org)'s libav libraries (libavcodec, libavformat, libavutil and libswscale), along with the libraries they need. `Scripts/build_dependencies.py` builds them from the sources pinned in `Scripts/build_dependencies.json`: arm64 only, for macOS 14 or later, LGPL and decode-only. The Xcode project finds their headers and libraries in `Dependencies/`, which git ignores.

_**Installation:**_ Do one of these:
* Download them: run `Scripts/fetch_dependencies.py`. CI builds the dependencies whenever their pinned sources change and publishes each build as a [GitHub release](https://github.com/znelson/CoreZen/releases); this downloads the one that matches your checkout. It needs only Python 3, including the one that comes with Xcode.
* Build them: run `Scripts/build_dependencies.py --output Dependencies`. This needs Xcode, git and Python 3.10 or later, but no libraries from Homebrew. Xcode's own Python is 3.9, which is too old for the build tools, so install a newer one from [python.org](https://www.python.org/downloads/macos/) or Homebrew. The first build downloads about 45 MB of sources and takes a few minutes; later runs rebuild only what changed. Build them when you change their pinned sources, since nothing is published for those until the change is merged.

See [`Scripts/update_instructions.md`](https://github.com/znelson/CoreZen/blob/main/Scripts/update_instructions.md) for updating them.

### Third-Party Licenses
`CoreZen.framework` contains code from other projects, under their own licenses:
* [FMDB](https://github.com/ccgus/fmdb) (MIT), linked into `CoreZen` itself. Its license is in [`CoreZen/Database/FMDB-LICENSE.txt`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/FMDB-LICENSE.txt).
* FFmpeg, mpv, libplacebo and FriBidi (LGPL 2.1 or later), FreeType (FreeType License), HarfBuzz (MIT), libass (ISC) and dav1d (BSD 2-Clause), as separate dynamic libraries. `Scripts/build_dependencies.py` collects their license texts, with a summary in `NOTICES.md`, into `Dependencies/licenses`.

The framework bundles both in its `Resources` folder, as `FMDB-LICENSE.txt` and `licenses/`, so an app that embeds it ships them. Such an app should point to them, for example from its About window, and credit FreeType there as its license asks; the credit line is at the end of `NOTICES.md`.

## What's In CoreZen.framework?

### 1. Preferences
[Create dynamic preference windows](https://github.com/znelson/CoreZen/tree/main/CoreZen/Preferences), inspired by [`CCNPreferencesWindowController`](https://github.com/phranck/CCNPreferencesWindowController).

### 2. Foundation Categories
[Categories to add functionality to Foundation classes](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories):
* [`NSFileManager+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSFileManager%2BCoreZen.h): get application support directory path and executable name
* [`NSNumber+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSNumber%2BCoreZen.h): generate a random integer
* [`NSURL+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSURL%2BCoreZen.h): find volume details from a URL or volume UUID, get relative paths between URLs, find a URL file size

### 3. Domain Data Modeling and Persistence

#### I. Object Identifiers
[`ZENIdentifier`](https://github.com/znelson/CoreZen/tree/main/CoreZen/Identifier/Identifier.h) is an _(atomically unique increasing)_ 64-bit integer identifier and the [`ZENIdentifiable`](https://github.com/znelson/CoreZen/tree/main/CoreZen/Identifier/Identifiable.h) protocol is for objects with such an identifier.

#### II. Object Cache
[`ZENObjectCache`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Cache/ObjectCache.h) is a thread safe object cache for [`ZENIdentifiable`](https://github.com/znelson/CoreZen/tree/main/CoreZen/Identifier/Identifiable.h) objects, configurable to hold either weak or strong refs to cached objects.

#### III. Database
[Helper classes around FMDB and sqlite3](https://github.com/znelson/CoreZen/tree/main/CoreZen/Database), including: 
* [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) is a database queue with both blocking and async execution options, and shutdown mechanics to handle outstanding async work. ([`FMDatabaseQueue` offers only blocking methods.](https://ccgus.github.io/fmdb/html/Classes/FMDatabaseQueue.html) [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) still works with [FMDB](https://github.com/ccgus/fmdb) [`FMDatabase`](https://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) instances and standard sqlite3 databases.)
* [`ZENDataTransferObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h) is a [`ZENIdentifiable`](https://github.com/znelson/CoreZen/tree/main/CoreZen/Identifier/Identifiable.h) object to build [DTOs](https://en.wikipedia.org/wiki/Data_transfer_object). [`ZENDataTransferObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h) serves as a base class for simple data storage objects which may be serialized (including to and from an sqlite3 database).
* The [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h) protocol to abstract the [FMDB](https://github.com/ccgus/fmdb) work for create, read, update, and delete operations on [`ZENDataTransferObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h)s on an sqlite3 database table.
* [`ZENDatabaseSchema`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseSchema.h) performs simple dynamic database schema updates based an array of [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h) objects.

*Note on dependencies:* [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) and other classes in `CoreZen` depend on [FMDB](https://github.com/ccgus/fmdb), which Swift Package Manager provides. [See above.](#fmdb-dependency)

#### IV. Domain Objects

[Helper classes to build a domain model](https://github.com/znelson/CoreZen/tree/main/CoreZen/Domain), including:
* [`ZENDomainObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) is a [`ZENIdentifiable`](https://github.com/znelson/CoreZen/tree/main/CoreZen/Identifier/Identifiable.h) object built around a [`ZENDataTransferObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h), allowing asynchronous initialization after initial creation or retrieval from database (or other serialization). Subclasses overriding `performAsyncInit:completion:` can do work such as checking a file's existence on disk, reading media file metadata, or even _fetching other objects from the database (which themselves can then perform asynchronous initialization work)_. [`ZENDomainObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) allows async init to be performed on an array of objects at once, and will automatically distribute the work using [dispatch queues](https://developer.apple.com/documentation/dispatch/1453057-dispatch_async).
* [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) is an object repository combining a [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) and a [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h) for object persistence, with a strong or weak [`ZENObjectCache`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Cache/ObjectCache.h). [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) exposes [`ZENDomainObjects`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) while hiding the details of storing and retrieving object [`ZENDataTransferObjects`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h) through [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h). [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) also hides the complexity of asynchronously initializing the domain objects after retrieval, and caches domain objects in its [`ZENObjectCache`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Cache/ObjectCache.h) to avoid repeated async initialization costs.

### 4. Media
[Classes to support reading audio and video media files](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media):
* [`ZENMediaFile`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/MediaFile.h) is a **_Work In Progress_**. Currently supports only basic media metadata retrieval including: video frame size, media duration, and audio and video codec names.

*Note on dependencies:* [`ZENMediaFile`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/MediaFile.h) and other classes in `CoreZen` depend on [libmpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/libmpv.rst) and [FFmpeg](https://ffmpeg.org). [See above.](#mpv-and-ffmpeg-dependencies)
