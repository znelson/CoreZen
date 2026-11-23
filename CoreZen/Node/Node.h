//
//  Node.h
//  CoreZen
//
//  Created by Zach Nelson on 7/20/22.
//

#import <Foundation/Foundation.h>

@class ZENNode;
NS_ASSUME_NONNULL_BEGIN

/// A block called for each node an enumeration visits, with its place in the
/// order they're visited, from 0.
///
/// Set `stop` to YES to end the enumeration.
typedef void (^ZENNodeEnumerateBlock)(id node, NSUInteger index, BOOL *stop);

/// A node in a tree of named nodes with sizes.
///
/// A leaf has its own size, and a node with children is as big as they are
/// together. Adding, removing and moving nodes keeps every total in the tree up
/// to date. A subclass can learn about changes below a node by overriding
/// ``childWasAdded:`` and the methods like it. Copying a node copies the nodes
/// below it too.
@interface ZENNode : NSObject <NSCopying>

/// A unique identifier, made with the node. A copy gets a new one.
@property (nonatomic, readonly, strong) NSUUID *nodeID;

/// The node's name.
@property (nonatomic, readonly, strong, nullable) NSString *name;

/// The node's size: a leaf's own, or else the total of its children's.
///
/// A leaf's own size comes from init. A node with children is as big as they
/// are together, so a leaf's own size gives way when it gets its first child.
/// Adding, removing and moving nodes keeps every total in the tree up to date.
@property (nonatomic, readonly) NSInteger size;

/// The node's parent, or nil if it has none.
@property (nonatomic, readonly, weak, nullable) ZENNode *parent;

/// The node's children, in the order they were added.
@property (nonatomic, readonly, strong) NSArray *children;

/// The number of the node's children.
@property (nonatomic, readonly) NSUInteger childCount;

/// Whether the node has no children.
@property (nonatomic, readonly) BOOL isChildless;

/// Makes a node with a name, and a size of 0.
- (instancetype)initWithName:(nullable NSString *)name;

/// Makes a node with a name and a size.
- (instancetype)initWithName:(nullable NSString *)name
						size:(NSInteger)size;

/// The top of the node's tree: its highest ancestor, or the node itself if it
/// has no parent.
- (id)rootNode;

/// The number of leaves below the node.
- (NSUInteger)countLeaves;

/// The number of nodes below the node.
- (NSUInteger)countChildrenAndDescendants;

/// Adds a node as the last child, moving it from its old parent if it has one.
///
/// Adding one of the node's children again does nothing.
- (void)addChildNode:(id)child;

/// Removes a child, if it's one of the node's children.
- (void)removeChildNode:(id)child;

/// Adds a copy of each of another node's children to this node.
- (void)copyChildren:(id)node;

/// Called after a child is added to this node.
///
/// A subclass can override it, calling super. Sizes are already updated when
/// it's called.
- (void)childWasAdded:(id)child;

/// Called after a child is removed from this node.
///
/// A subclass can override it, calling super. Sizes are already updated when
/// it's called.
- (void)childWasRemoved:(id)child;

/// Called after a node is added deeper below this node, to one of its
/// descendants.
///
/// A subclass can override it, calling super. Sizes are already updated when
/// it's called.
- (void)descendantWasAdded:(id)descendant;

/// Called after a node is removed from deeper below this node, from one of its
/// descendants.
///
/// A subclass can override it, calling super. Sizes are already updated when
/// it's called.
- (void)descendantWasRemoved:(id)descendant;

/// Sets the size to the total of the children's sizes, and updates the
/// ancestors' totals to match.
///
/// On a leaf, this drops the size it was made with.
- (void)resetSize;

/// Calls a block for each of the node's children, in order.
- (void)enumerateChildrenWithBlock:(ZENNodeEnumerateBlock)block;

/// Calls a block for each of the node's ancestors, from its parent up to the
/// top of the tree.
- (void)enumerateParentsWithBlock:(ZENNodeEnumerateBlock)block;

/// Calls a block for every node below this one, depth first, visiting each node
/// after the nodes below it.
- (void)enumerateDepthFirstUsingBlock:(ZENNodeEnumerateBlock)block;

/// Calls a block for every node below this one, breadth first: the children,
/// then the grandchildren, and so on.
- (void)enumerateBreadthFirstUsingBlock:(ZENNodeEnumerateBlock)block;

@end

NS_ASSUME_NONNULL_END
