# ``ZENNode``

## Topics

### Creating a Node

- ``initWithName:``
- ``initWithName:size:``
- ``copyChildren:``

### Identifying a Node

- ``nodeID``
- ``name``

### Size

- ``size``
- ``resetSize``

### The Tree

- ``parent``
- ``children``
- ``childCount``
- ``isChildless``
- ``rootNode``
- ``countLeaves``
- ``countChildrenAndDescendants``

### Adding and Removing Nodes

- ``addChildNode:``
- ``removeChildNode:``

### Enumerating Nodes

- ``enumerateChildrenWithBlock:``
- ``enumerateParentsWithBlock:``
- ``enumerateDepthFirstUsingBlock:``
- ``enumerateBreadthFirstUsingBlock:``
- ``ZENNodeEnumerateBlock``

### Learning About Changes

- ``childWasAdded:``
- ``childWasRemoved:``
- ``descendantWasAdded:``
- ``descendantWasRemoved:``
