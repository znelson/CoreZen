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
			
			[self.mutableChildren addObject:child];
			child.parent = self;
			
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

- (void)childWasAdded:(ZENNode *)child {
	// To be overridden in derived classes
	// Be sure to call [super childWasAdded:child]
	if (self.children.count == 1) {
		self.size = child.size;
	} else {
		self.size += child.size;
	}
}

- (void)childWasRemoved:(ZENNode *)child {
	// To be overridden in derived classes
	// Be sure to call [super childWasRemoved:child]
	self.size -= child.size;
}

- (void)descendantWasAdded:(ZENNode *)descendant {
	// To be overridden in derived classes
	// Be sure to call [super descendantWasAdded:child]
	self.size += descendant.size;
}

- (void)descendantWasRemoved:(ZENNode *)descendant {
	// To be overridden in derived classes
	// Be sure to call [super descendantWasRemoved:child]
	self.size -= descendant.size;
}

- (void)resetSize {
	self.size = 0;
	for (ZENNode *child in self.children) {
		self.size += child.size;
	}
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
