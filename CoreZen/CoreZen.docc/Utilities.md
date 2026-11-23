# Utilities

A work queue whose work can be canceled, a tree of nodes with sizes, a preferences window, views loaded from nibs, and additions to Foundation and AppKit classes.

## Overview

- ``ZENWorkQueue`` is a serial queue whose async work can be canceled, and which can be terminated.
- ``ZENNode`` is a tree of named nodes with sizes, where every node's size stays the total of its children's.
- ``ZENPreferencesWindowController`` is a preferences window with a toolbar item for each pane.
- ``ZENArchivedView-c.class`` is a view that loads its contents from a nib its subclass names.

### Cancel Queued Work

```objc
ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"com.example.thumbnails"];
ZENWorkQueueToken *work = [queue async:^(ZENWorkQueueToken *token) {
    if (token.canceled) {
        return;
    }
    // Do the work
}];

// If the work is no longer needed
[work cancel];

// Before the app quits
[queue terminate:^{
    // Runs once the work already queued has run
}];
```

A block that's queued always runs, so it checks its token to learn whether it should skip its work.

### Total Sizes in a Tree

```objc
ZENNode *movies = [[ZENNode alloc] initWithName:@"Movies"];
[movies addChildNode:[[ZENNode alloc] initWithName:@"a.mp4" size:700]];
[movies addChildNode:[[ZENNode alloc] initWithName:@"b.mp4" size:300]];
// movies.size is 1000
```

### Foundation and AppKit Additions

CoreZen adds methods, named with a `zen_` prefix, to a few Foundation and AppKit classes. Xcode's Quick Help shows their documentation, but they have no pages here, because Xcode's documentation build leaves out categories on other frameworks' classes.

- term `NSURL`: `zen_volumeName:volumeURL:volumeUUID:error:` gets the name, URL and UUID of the volume a URL is on, and `zen_volumeInfoForUUID:volumeName:volumeURL:` finds a volume again by its UUID. Some volumes, like many network shares, have no UUID. `zen_relativePathToURL:` gives a URL's path relative to another URL, such as its volume's, and `zen_URLByAppendingRelativePath:isDirectory:` turns it back into a URL. `zen_fileSize` gives a file's size.
- term `NSFileManager`: `zen_findOrCreateURLForDirectory:inDomain:appendPathComponent:create:error:` finds or creates a standard folder, `zen_applicationSupportDirectory` gives the app's own folder in Application Support, and `zen_executableName` gives the name of the app's executable.
- term `NSView`: `zen_addConstraintsForEqualSizes:` makes a subview fill a view.
- term `NSNumber`: `zen_randomInteger` gives a random integer.

## Topics

### Work Queues

- ``ZENWorkQueue``
- ``ZENWorkQueueToken``
- ``ZENWorkQueueBlock``
- ``ZENWorkQueueCancelBlock``

### Trees

- ``ZENNode``

### Preferences

- ``ZENPreferencesWindowController``
- ``ZENPreferenceViewController``

### Views

- ``ZENArchivedView-c.class``
- ``ZENArchivedView-c.protocol``
