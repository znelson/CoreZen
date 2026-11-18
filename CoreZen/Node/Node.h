//
//  Node.h
//  CoreZen
//
//  Created by Zach Nelson on 7/20/22.
//

#import <Foundation/Foundation.h>

@class ZENNode;
typedef void (^ZENNodeEnumerateBlock)(id node, NSUInteger index, BOOL *stop);

@interface ZENNode : NSObject <NSCopying>

@property (nonatomic, readonly, strong) NSUUID *nodeID;

@property (nonatomic, readonly, strong) NSString *name;

// A leaf's own size, from init. A node with children is as big as they are
// together, so a leaf's own size gives way when it gets its first child. Adding,
// removing and moving nodes keeps every total in the tree up to date.
@property (nonatomic, readonly) NSInteger size;

@property (nonatomic, readonly, weak) ZENNode *parent;
@property (nonatomic, readonly, strong) NSArray *children;
@property (nonatomic, readonly) NSUInteger childCount;
@property (nonatomic, readonly) BOOL isChildless;

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name
						size:(NSInteger)size;

- (id)rootNode;
- (NSUInteger)countLeaves;
- (NSUInteger)countChildrenAndDescendants;

- (void)addChildNode:(id)child;
- (void)removeChildNode:(id)child;

- (void)copyChildren:(id)node;

// For subclasses to override, calling super. They run after a child of this node,
// or a node deeper below it, is added or removed, when sizes are already updated.
- (void)childWasAdded:(id)child;
- (void)childWasRemoved:(id)child;

- (void)descendantWasAdded:(id)descendant;
- (void)descendantWasRemoved:(id)descendant;

// Sets the size to the total of the children's sizes, and updates the ancestors'
// totals to match. On a leaf, this drops the size it was made with.
- (void)resetSize;

- (void)enumerateChildrenWithBlock:(ZENNodeEnumerateBlock)block;
- (void)enumerateParentsWithBlock:(ZENNodeEnumerateBlock)block;

- (void)enumerateDepthFirstUsingBlock:(ZENNodeEnumerateBlock)block;
- (void)enumerateBreadthFirstUsingBlock:(ZENNodeEnumerateBlock)block;

@end
