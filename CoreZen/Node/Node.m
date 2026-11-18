//
//  Node.m
//  CoreZen
//
//  Created by Zach Nelson on 7/20/22.
//

#import "Node.h"

@interface ZENNode ()

@property (nonatomic, strong, readonly) NSMutableArray<ZENNode *> *mutableChildren;
@property (nonatomic, weak) ZENNode *parent;
@property (nonatomic) NSInteger size;

- (void)enumerateDepthFirstHelper:(ZENNodeEnumerateBlock)block index:(NSUInteger *)index stop:(BOOL *)stop;

- (void)addToSize:(NSInteger)change;

- (instancetype)initZEN:(NSString *)name
				   size:(NSInteger)size;

@end

@implementation ZENNode

- (instancetype)initZEN:(NSString *)name
				   size:(NSInteger)size {
	self = [super init];
	if (self) {
		_nodeID = [NSUUID UUID];
		_mutableChildren = [NSMutableArray new];
		_name = name;
		_size = size;
	}
	return self;
}

- (instancetype)init {
	self = [self initZEN:nil size:0];
	return self;
}

- (instancetype)initWithName:(NSString *)name {
	self = [self initZEN:name size:0];
	return self;
}

- (instancetype)initWithName:(NSString *)name
						size:(NSInteger)size {
	self = [self initZEN:name size:size];
	return self;
}

- (id)rootNode {
	ZENNode *node = self;
	while (node.parent) {
		node = node.parent;
	}
	return node;
}

- (NSUInteger)countLeaves {
	__block NSUInteger count = 0;
	[self enumerateDepthFirstUsingBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		if (node.isChildless) {
			++count;
		}
	}];
	return count;
}

- (NSUInteger)countChildrenAndDescendants {
	__block NSUInteger count = 0;
	[self enumerateDepthFirstUsingBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		++count;
	}];
	return count;
}

- (NSArray *)children {
	return [self.mutableChildren copy];
}

- (NSUInteger)childCount {
	return self.mutableChildren.count;
}

- (BOOL)isChildless {
	return (self.mutableChildren.count == 0);
}

- (void)addChildNode:(ZENNode *)child {
	NSUInteger childIndex = [self.mutableChildren indexOfObject:child];
	if (childIndex == NSNotFound) {
		ZENNode *oldParent = child.parent;
		if (oldParent != self) {
			if (oldParent) {
				[oldParent removeChildNode:child];
			}

			// A node with children is as big as they are together, so a leaf's own
			// size gives way to its first child's
			NSInteger sizeChange = self.isChildless ? child.size - self.size : child.size;

			[self.mutableChildren addObject:child];
			child.parent = self;
			[self addToSize:sizeChange];

			[self childWasAdded:child];
			[self enumerateParentsWithBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
				[node descendantWasAdded:child];
			}];
		}
	}
}

- (void)removeChildNode:(ZENNode *)child {
	NSUInteger childIndex = [self.mutableChildren indexOfObject:child];
	if (childIndex != NSNotFound) {
		[self.mutableChildren removeObjectAtIndex:childIndex];
		child.parent = nil;
		[self addToSize:-child.size];

		[self childWasRemoved:child];
		[self enumerateParentsWithBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
			[node descendantWasRemoved:child];
		}];
	}
}

- (id)copyWithZone:(NSZone *)zone {
	ZENNode *copy = [[self.class allocWithZone:zone] initWithName:self.name size:self.size];
	[copy copyChildren:self];
	return copy;
}

- (void)copyChildren:(ZENNode *)node {
	for (ZENNode *child in node.children) {
		[self addChildNode:[child copy]];
	}
}

// Every ancestor's size counts this node's, so a change to it changes theirs too
- (void)addToSize:(NSInteger)change {
	if (change == 0) {
		return;
	}
	for (ZENNode *node = self; node; node = node.parent) {
		node.size += change;
	}
}

// The hooks are for subclasses. Sizes are already updated when they run, so these
// do nothing; overrides should still call super.

- (void)childWasAdded:(ZENNode *)child {
}

- (void)childWasRemoved:(ZENNode *)child {
}

- (void)descendantWasAdded:(ZENNode *)descendant {
}

- (void)descendantWasRemoved:(ZENNode *)descendant {
}

- (void)resetSize {
	NSInteger total = 0;
	for (ZENNode *child in self.mutableChildren) {
		total += child.size;
	}
	[self addToSize:total - self.size];
}

- (void)enumerateChildrenWithBlock:(ZENNodeEnumerateBlock)block {
	BOOL stop = NO;
	NSUInteger index = 0;
	for (ZENNode *child in self.children) {
		block(child, index, &stop);
		++index;
		if (stop) {
			break;
		}
	}
}

- (void)enumerateParentsWithBlock:(ZENNodeEnumerateBlock)block {
	BOOL stop = NO;
	NSUInteger index = 0;
	ZENNode *node = self.parent;
	while (node) {
		block(node, index, &stop);
		++index;
		if (stop) {
			break;
		}
		node = node.parent;
	}
}

- (void)enumerateDepthFirstHelper:(ZENNodeEnumerateBlock)block
							index:(NSUInteger *)index
							 stop:(BOOL *)stop {
	for (ZENNode *node in self.children) {
		[node enumerateDepthFirstHelper:block index:index stop:stop];
		if (*stop) {
			break;
		}
		block(node, *index, stop);
		++(*index);
		if (*stop) {
			break;
		}
	}
}

- (void)enumerateDepthFirstUsingBlock:(ZENNodeEnumerateBlock)block {
	NSUInteger index = 0;
	BOOL stop = NO;
	[self enumerateDepthFirstHelper:block index:&index stop:&stop];
}

- (void)enumerateBreadthFirstUsingBlock:(ZENNodeEnumerateBlock)block {
	NSUInteger index = 0;
	BOOL stop = NO;
	NSMutableArray<ZENNode *> *queue = [NSMutableArray arrayWithArray:self.children];
	while (queue.count > 0 && !stop) {
		ZENNode *node = queue.firstObject;
		[queue removeObjectAtIndex:0];
		block(node, index, &stop);
		++index;
		if (!stop) {
			[queue addObjectsFromArray:node.children];
		}
	}
}

@end
