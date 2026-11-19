# Persistence

Store a domain model in SQLite, and load, cache and save its objects asynchronously.

## Overview

An app describes each table with three classes:

- A table class, which conforms to ``ZENDatabaseTable``, creates and migrates the table, and reads and writes its rows.
- A data transfer object (DTO), a subclass of ``ZENDataTransferObject``, holds one row's values in properties.
- A domain object, a subclass of ``ZENDomainObject-c.class``, is what the rest of the app works with. It's built around a DTO, and adds whatever the app needs beyond the stored values.

A ``ZENObjectRepository`` brings these together with a ``ZENDatabaseQueue``. It loads the objects, keeps one in memory for each identifier, and saves changes, all asynchronously. Each object has a ``ZENIdentifier`` from ``ZENGetNextObjectIdentifier``, which is unique across every database the process opens.

### Describe a Table

For a table of notes, each with some text:

```objc
@interface NoteDTO : ZENDataTransferObject
@property (nonatomic, copy, nullable) NSString *text;
@end

@interface Note : ZENDomainObject
@end

@interface NoteTable : NSObject <ZENDatabaseTable>
@end

@implementation NoteTable

+ (NSString *)tableName {
    return @"notes";
}

+ (BOOL)updateSchema:(ZENDatabase *)database version:(NSUInteger)version {
    if (version == 1) {
        [database executeUpdate:@"CREATE TABLE notes (identifier INTEGER PRIMARY KEY, text TEXT);"];
        return YES;
    }
    return NO;
}

- (BOOL)insertDTO:(ZENDataTransferObject *)dto database:(ZENDatabase *)database {
    NoteDTO *note = (NoteDTO *)dto;
    return [database executeUpdate:@"INSERT INTO notes (identifier, text) VALUES (?, ?);",
                                   @(note.identifier), note.text ?: NSNull.null];
}

- (ZENDataTransferObject *)dtoFromRow:(ZENResultSet *)row {
    NoteDTO *note = [[NoteDTO alloc] initWithIdentifier:[row longLongIntForColumnIndex:0]];
    note.text = [row stringForColumnIndex:1];
    return note;
}

- (ZENResultSet *)allRows:(ZENDatabase *)database {
    return [database executeQuery:@"SELECT identifier, text FROM notes;"];
}

// updateDTO:database:, deleteByIdentifier:database:, rowByIdentifier:database:
// and countAllRows: work the same way.

@end
```

A later version of the schema adds a branch for version 2, and so on. Each version's change runs once.

### Open the Database

A ``ZENDatabaseSchema`` brings the database up to the latest version of every table's schema:

```objc
ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:databaseURL];
ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[NoteTable.class]];
[queue transactionSync:^(ZENDatabase *database) {
    [schema initializeDatabase:database];
}];
```

### Load and Save Objects

A repository for the table makes a `Note` from each row:

```objc
ZENObjectRepository *notes = [[ZENObjectRepository alloc] initWithDataModel:nil
                                                                 tableClass:NoteTable.class
                                                              databaseQueue:queue
                                                         domainObjectEmbryo:Note.class
                                                                  cacheType:ZENObjectRepositoryCacheType_Weak];

NoteDTO *dto = [[NoteDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier()];
dto.text = @"Buy milk";
[notes addObject:[[Note alloc] initWithDTO:dto] uiCompletion:^(NSError *error) {
    // nil once the note is saved, or else why it wasn't
}];

[notes fetchAllObjectsForUI:^(NSArray *fetchedObjects) {
    // Every note
}];
```

The repository runs these one after the other on the database queue, so the fetch finds the new note. Each write's completion gets nil once the change is saved, or an error in ``ZENDatabaseErrorDomain`` that says why it wasn't. An object that observes the repository, with ``ZENObjectRepository/zen_addObserver:selector:``, hears about each saved change on the main thread.

## Topics

### Repositories

- ``ZENObjectRepository``

### Domain Objects

- ``ZENDomainObject-c.class``
- ``ZENDomainObject-c.protocol``
- ``ZENDataModel``

### Tables

- ``ZENDatabaseTable``
- ``ZENDataTransferObject``
- ``ZENDatabaseSchema``

### Databases

- ``ZENDatabaseQueue``
- ``ZENDatabase``
- ``ZENResultSet``
- ``ZENDatabaseErrorDomain``
- ``ZENDatabaseErrorCode``

### Identifiers

- ``ZENIdentifier``
- ``ZENInvalidIdentifier``
- ``ZENIdentifiable``
- ``ZENGetNextObjectIdentifier``
- ``ZENSetLargestObjectIdentifier``

### Caching

- ``ZENObjectCache``

### Asynchronous Callbacks

- ``ZENAsyncCompletionBlock``
- ``ZENAsyncContinueBlock``
- ``ZENFetchResultsBlock``
- ``ZENAsyncCountCompletionBlock``
- ``ZENCallAsyncCompletionBlockOnThreadPool``
- ``ZENCallAsyncCompletionBlockOnMainThread``
- ``ZENCallAsyncContinueBlockOnThreadPool``
- ``ZENCallAsyncContinueBlockOnMainThread``
- ``ZENCallFetchResultsBlockOnThreadPool``
- ``ZENCallFetchResultsBlockOnMainThread``
- ``ZENCallAsyncCountCompletionBlockOnThreadPool``
- ``ZENCallAsyncCountCompletionBlockOnMainThread``
- ``ZENDeliverNotificationOnMainThread``
- ``ASSERT_MAIN_THREAD``
