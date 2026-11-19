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

### Logging

CoreZen logs to the unified log, under the subsystem `com.zdnelson.CoreZen`, in the categories Database, Domain, Media, Player and General. Failures are errors, harmless surprises like a method called twice are default messages, and routine events like a database opening are info. Paths, URLs and mpv's messages are private, since they can name the user's files. To watch them:

```
log stream --level info --predicate 'subsystem == "com.zdnelson.CoreZen"'
```

### Versions

CoreZen follows [Semantic Versioning](https://semver.org). Each release is a git tag such as `v0.1.0`, with a [GitHub release](https://github.com/znelson/CoreZen/releases) whose notes come from [`CHANGELOG.md`](https://github.com/znelson/CoreZen/blob/main/CHANGELOG.md). Until 1.0.0, a release that breaks the API raises the middle number (0.1.0 to 0.2.0), and any other release raises the last (0.1.0 to 0.1.1). At run time, the framework bundle's `CFBundleShortVersionString` is its version.

To release a version:
1. In a pull request, rename CHANGELOG.md's Unreleased section to the version and date, such as `## 0.2.0 - 2026-12-01`, and add an empty Unreleased section above it. Set the CoreZen target's Version in Xcode (`MARKETING_VERSION`) to the same number. CI runs `Scripts/check_version.py`, which checks that the two match.
2. Once it's merged, tag the merge commit on main and push the tag: `git tag v0.2.0 && git push origin v0.2.0`. The Release workflow checks the tag against both, then publishes the GitHub release.

## What's In CoreZen.framework?

`CoreZen` has three parts: a persistence layer for a domain model stored in SQLite, media playback and frame rendering built on mpv and FFmpeg, and smaller AppKit and Foundation helpers. The public headers say which values can be `nil`.

### 1. Persistence

A domain model stored in SQLite: a table class for each table, plain data objects for its rows, domain objects built from those, and repositories that load, cache and save the domain objects asynchronously. It's built on [FMDB](https://github.com/ccgus/fmdb). [See above.](#fmdb-dependency)

#### Identifiers
* [`ZENIdentifier`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Identifier/Identifier.h) is a 64-bit integer identifier, and the [`ZENIdentifiable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Identifier/Identifiable.h) protocol is for objects that have one.
* [`ZENGetNextObjectIdentifier()`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Identifier/ObjectIdentifier.h) hands out identifiers from one counter for the whole process, shared by every table, so an identifier is unique across every database the process opens. When `ZENDatabaseSchema` initializes a database, it moves the counter past the largest identifier stored there.

#### Database
* [`ZENDatabaseQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseQueue.h) runs blocks on a database one at a time, synchronously or asynchronously. Each queue has one SQLite connection, so anything that belongs to a connection, like a temporary table, lasts from one block to the next.
  * A transaction block commits when it returns, or rolls back if any statement in it fails or it calls `cancelTransaction`.
  * `shutdown:` runs the async work already queued, then a final block of your own, then closes the database. Work queued after that doesn't run.
  * A database file uses SQLite's write-ahead log, so a write and reads on other connections don't wait for each other, and a power loss can undo the last commits but not corrupt the database. The file gets two companions, `-wal` and `-shm`, which go wherever it goes.
  * `ZENDatabaseQueueOptionForeignKeys` turns on SQLite's enforcement of `REFERENCES` clauses, which is off unless asked for.
  * An in-memory queue has a database of its own, which is handy for tests.
* [`ZENDatabase`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/Database.h) and [`ZENResultSet`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/ResultSet.h) run statements and read their results, wrapping FMDB's classes.
* A class for each table conforms to [`ZENDatabaseTable`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseTable.h): it creates and migrates the table, and inserts, updates, deletes, reads and counts its rows as [`ZENDataTransferObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DataTransferObject.h)s. A data transfer object (DTO) holds one row's values in properties its subclass declares, and can be copied.
* [`ZENDatabaseSchema`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/DatabaseSchema.h) brings a database up to the latest version of every table's schema, in one transaction, and records the version in SQLite's `user_version`. A migration that fails rolls back entirely, so it runs again the next time.
* When changes aren't saved, errors in `ZENDatabaseErrorDomain` (declared in [`Database.h`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Database/Database.h)) say why: a statement failed, the transaction was canceled, the commit failed, the database couldn't be opened, or a table refused the write.

#### Domain Objects
* [`ZENDomainObject`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/DomainObject.h) is built around a DTO. A subclass can override `performAsyncInit:completion:` to finish setting itself up after it's created or loaded, such as checking a file on disk, reading media metadata, or fetching related objects, and report an error if that fails. `+asyncInit:model:completion:` runs it for several objects at once on a thread pool.
* [`ZENObjectRepository`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Domain/ObjectRepository.h) combines a table, a database queue and a [`ZENObjectCache`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Cache/ObjectCache.h), which holds its objects weakly or strongly.
  * Each identifier has one object in memory, so every part of an app sees the same one.
  * Fetches get every object, the object with an identifier, or with `fetchObjectsWithQuery:completion:`, the objects in the rows a query returns, such as a query method of the table class's own.
  * Fetches deliver objects only once their async init has finished. Init runs once per object, and an object whose init fails is left out.
  * Add, update and delete are each a transaction of their own, and their completion reports `nil` once the change is saved, or the error. Only a saved change updates the cache and posts `ZENObjectRepositoryObjectAddedNotification`, `...UpdatedNotification` or `...DeletedNotification`, on the main thread.
  * `+performWrites:completion:` saves several writes, to objects in one or more repositories that share a database queue, in one transaction: all of them or none.
  * Every method is asynchronous. Each has a variant that calls back on the main thread (`uiCompletion:` or `ForUI`).

### 2. Media

Playback with [libmpv](https://github.com/mpv-player/mpv/blob/master/DOCS/man/libmpv.rst), and file details and frames with [FFmpeg](https://ffmpeg.org)'s libav libraries. [See above.](#mpv-and-ffmpeg-dependencies)

* [`ZENMediaPlayer`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/MediaPlayer.h) plays a file with mpv. Its `fileURL`, `paused`, `positionPercent` and `seeking` properties change only on the main thread, so a UI can observe them. Seeks run one at a time, and one requested before the file has loaded waits for it.
* [`ZENMediaPlayerView`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/Views/MediaPlayerView.h) shows a player's video. It's an `NSOpenGLView`, because OpenGL is the only GPU rendering mpv's render API offers on macOS. [`ZENMediaPlayerControlsView`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/Views/MediaPlayerControlsView.h) has play/pause, frame step and skip buttons, and [`ZENMediaPlayerCTIView`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/Views/MediaPlayerCTIView.h) is a timeline that shows and sets the position, and previews the frame under the pointer.
* [`ZENMediaFile`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/MediaFile.h) reads a file's duration, frame size and codec names.
* [`ZENFrameRenderer`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Media/FrameRenderer.h) renders a file's frames as `NSImage`s for thumbnails: one at a given time or percentage, or several spread across the file. It shows the keyframe at or before each time, which is fast, and reports which time that was. A render can be canceled.
* An app should call `+[ZENMediaPlayer terminateAllPlayers]` and `+[ZENMediaFile terminateAllMediaFiles]` before it quits.

### 3. Utilities

* [`ZENWorkQueue`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Queue/WorkQueue.h) is a serial queue whose async work can be canceled through the token it returns. Terminating it runs a final block after the current work; blocks still waiting see that they're canceled, and later ones don't run.
* [`ZENNode`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Node/Node.h) is a tree of named nodes with sizes. A leaf has its own size and a node with children is as big as they are together, and every total stays up to date as nodes are added, removed and moved. Nodes can be enumerated depth first or breadth first, and copied.
* [`ZENPreferencesWindowController`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Preferences/PreferencesWindowController.h) builds a preferences window with a toolbar item for each view controller that conforms to [`ZENPreferenceViewController`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Preferences/PreferenceViewController.h). It's adapted from [`CCNPreferencesWindowController`](https://github.com/phranck/CCNPreferencesWindowController).
* [`ZENArchivedView`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Views/ArchivedView.h) is a view that loads its contents from a nib its subclass names.
* Categories on Foundation and AppKit classes:
  * [`NSFileManager+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSFileManager%2BCoreZen.h): find or create a standard folder, like the app's own folder in Application Support, and get the app's executable name.
  * [`NSURL+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSURL%2BCoreZen.h): find a URL's volume name, URL and UUID, or a volume by its UUID; get the path from one URL to another and back; get a file's size.
  * [`NSView+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSView%2BCoreZen.h): add constraints that make a subview fill a view.
  * [`NSNumber+CoreZen`](https://github.com/znelson/CoreZen/blob/main/CoreZen/Categories/NSNumber%2BCoreZen.h): generate a random integer.
