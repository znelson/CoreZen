# CoreZen.framework

A macOS Cocoa framework made up of useful bits of code from my side projects.

Written by [Zach Nelson](https://github.com/znelson). See the [LICENSE file](https://github.com/znelson/CoreZen/blob/main/LICENSE) for license info (it's the MIT license).

## Getting Started

### FMDB.framework Dependency
`CoreZen` links against and bundles [FMDB.framework](https://github.com/ccgus/fmdb). The Xcode project is set up to find FMDB installed using [Carthage](https://github.com/Carthage/Carthage#quick-start).

_**Installation:**_ Run `carthage update --platform mac` to build Carthage/Build/Mac/FMDB.framework. The `CoreZen` Xcode project will find it from there.

### mpv and libav Dependencies
`CoreZen` links against and bundles dynamic libraries for [libmpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/libmpv.rst) and [libav](https://github.com/libav/libav#readme). The Xcode project is set up to find headers and libraries installed using [Homebrew](https://brew.sh).

_**Installation:**_
1. Run `brew install mpv ffmpeg` to install mpv and libav. 
1. Run `Scripts/stage_dependencies.py`. This will gather mpv and libav dylibs and headers into Dependencies/lib and Dependencies/include, respectively. The `CoreZen` Xcode project will find them there.

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

*Note on dependencies:* [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) and other classes in `CoreZen` depend on [FMDB.framework](https://github.com/ccgus/fmdb). [See above for installation from Carthage.](#fmdbframework-dependency)

#### IV. Domain Objects

[Helper classes to build a domain model](https://github.com/znelson/CoreZen/tree/main/CoreZen/Domain), including:
* [`ZENDomainObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) is a [`ZENIdentifiable`](https://github.com/znelson/CoreZen/tree/main/CoreZen/Identifier/Identifiable.h) object built around a [`ZENDataTransferObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h), allowing asynchronous initialization after initial creation or retrieval from database (or other serialization). Subclasses overriding `performAsyncInit:completion:` can do work such as checking a file's existence on disk, reading media file metadata, or even _fetching other objects from the database (which themselves can then perform asynchronous initialization work)_. [`ZENDomainObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) allows async init to be performed on an array of objects at once, and will automatically distribute the work using [dispatch queues](https://developer.apple.com/documentation/dispatch/1453057-dispatch_async).
* [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) is an object repository combining a [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) and a [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h) for object persistence, with a strong or weak [`ZENObjectCache`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Cache/ObjectCache.h). [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) exposes [`ZENDomainObjects`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) while hiding the details of storing and retrieving object [`ZENDataTransferObjects`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h) through [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h). [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) also hides the complexity of asynchronously initializing the domain objects after retrieval, and caches domain objects in its [`ZENObjectCache`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Cache/ObjectCache.h) to avoid repeated async initialization costs.

### 4. Media
[Classes to support reading audio and video media files](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media):
* [`ZENMediaFile`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/MediaFile.h) is a **_Work In Progress_**. Currently supports only basic media metadata retrieval including: video frame size, media duration, and audio and video codec names.

*Note on dependencies:* [`ZENMediaFile`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/MediaFile.h) and other classes in `CoreZen` depend on [libmpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/libmpv.rst) and [libav](https://github.com/libav/libav#readme). [See above for installation from Homebrew.](#mpv-and-libav-dependencies)
