# ``ZENObjectRepository``

## Topics

### Creating a Repository

- ``initWithDataModel:tableClass:databaseQueue:domainObjectEmbryo:cacheType:``
- ``ZENObjectRepositoryCacheType``

### Fetching Objects

- ``fetchAllObjects:``
- ``fetchAllObjectsForUI:``
- ``fetchObjectByIdentifier:completion:``
- ``fetchObjectByIdentifier:uiCompletion:``
- ``fetchObjectsWithQuery:completion:``
- ``fetchObjectsWithQuery:uiCompletion:``
- ``ZENRepositoryQuery``

### Counting and Summing

- ``countAllObjects:``
- ``countAllObjectsForUI:``
- ``sumColumn:completion:``
- ``sumColumn:uiCompletion:``

### Saving Objects

- ``addObject:completion:``
- ``addObject:uiCompletion:``
- ``asyncInitAndAdd:completion:``
- ``asyncInitAndAdd:uiCompletion:``
- ``updateObject:completion:``
- ``updateObject:uiCompletion:``
- ``deleteObject:completion:``
- ``deleteObject:uiCompletion:``

### Saving Several Writes Together

- ``performWrites:completion:``
- ``performWrites:uiCompletion:``
- ``ZENRepositoryWriteBatch``

### Observing Changes

- ``zen_addObserver:selector:``
- ``zen_removeObserver:``
- ``ZENObjectRepositoryObjectAddedNotification``
- ``ZENObjectRepositoryObjectUpdatedNotification``
- ``ZENObjectRepositoryObjectDeletedNotification``
- ``ZENObjectRepositoryNotificationObjectKey``
