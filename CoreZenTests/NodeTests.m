//
//  NodeTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

// Records each hook call, with the node's size when it ran
@interface ZENRecordingNode : ZENNode
@property (nonatomic, strong) NSMutableArray<NSString *> *calls;
@end

@implementation ZENRecordingNode

- (NSMutableArray<NSString *> *)calls {
	if (!_calls) {
		_calls = [NSMutableArray new];
	}
	return _calls;
}

- (void)record:(NSString *)hook node:(ZENNode *)node {
	[self.calls addObject:[NSString stringWithFormat:@"%@ %@ at %ld", hook, node.name, (long)self.size]];
}

- (void)childWasAdded:(id)child {
	[super childWasAdded:child];
	[self record:@"childWasAdded" node:child];
}

- (void)childWasRemoved:(id)child {
	[super childWasRemoved:child];
	[self record:@"childWasRemoved" node:child];
}

- (void)descendantWasAdded:(id)descendant {
	[super descendantWasAdded:descendant];
	[self record:@"descendantWasAdded" node:descendant];
}

- (void)descendantWasRemoved:(id)descendant {
	[super descendantWasRemoved:descendant];
	[self record:@"descendantWasRemoved" node:descendant];
}

@end

@interface NodeTests : XCTestCase

@end

@implementation NodeTests

// Every node with children should be exactly as big as its children together
- (void)assertSizesAddUp:(ZENNode *)root {
	NSMutableArray<ZENNode *> *nodes = [NSMutableArray arrayWithObject:root];
	[root enumerateDepthFirstUsingBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		[nodes addObject:node];
	}];
	for (ZENNode *node in nodes) {
		if (node.isChildless) {
			continue;
		}
		NSInteger total = 0;
		for (ZENNode *child in node.children) {
			total += child.size;
		}
		XCTAssertEqual(node.size, total, @"%@ should be as big as its children together", node.name);
	}
}

#pragma mark - Initialization

- (void)testInitWithName {
	ZENNode *node = [[ZENNode alloc] initWithName:@"root"];
	XCTAssertNotNil(node);
	XCTAssertEqualObjects(node.name, @"root");
	XCTAssertEqual(node.size, 0);
	XCTAssertNotNil(node.nodeID);
}

- (void)testInitWithNameAndSize {
	ZENNode *node = [[ZENNode alloc] initWithName:@"file" size:1024];
	XCTAssertEqualObjects(node.name, @"file");
	XCTAssertEqual(node.size, 1024);
}

- (void)testUniqueNodeIDs {
	ZENNode *a = [[ZENNode alloc] initWithName:@"a"];
	ZENNode *b = [[ZENNode alloc] initWithName:@"b"];
	XCTAssertNotEqualObjects(a.nodeID, b.nodeID);
}

#pragma mark - Parent / Child

- (void)testAddChildSetsParent {
	ZENNode *parent = [[ZENNode alloc] initWithName:@"parent"];
	ZENNode *child = [[ZENNode alloc] initWithName:@"child"];
	[parent addChildNode:child];

	XCTAssertEqual(child.parent, parent);
	XCTAssertEqual(parent.childCount, 1u);
	XCTAssertFalse(parent.isChildless);
}

- (void)testRemoveChildClearsParent {
	ZENNode *parent = [[ZENNode alloc] initWithName:@"parent"];
	ZENNode *child = [[ZENNode alloc] initWithName:@"child"];
	[parent addChildNode:child];
	[parent removeChildNode:child];

	XCTAssertNil(child.parent);
	XCTAssertEqual(parent.childCount, 0u);
	XCTAssertTrue(parent.isChildless);
}

- (void)testAddChildTransfersFromOldParent {
	ZENNode *parentA = [[ZENNode alloc] initWithName:@"A"];
	ZENNode *parentB = [[ZENNode alloc] initWithName:@"B"];
	ZENNode *child = [[ZENNode alloc] initWithName:@"child"];

	[parentA addChildNode:child];
	XCTAssertEqual(parentA.childCount, 1u);

	[parentB addChildNode:child];
	XCTAssertEqual(parentA.childCount, 0u);
	XCTAssertEqual(parentB.childCount, 1u);
	XCTAssertEqual(child.parent, parentB);
}

- (void)testAddingSameChildTwiceIsNoOp {
	ZENNode *parent = [[ZENNode alloc] initWithName:@"parent"];
	ZENNode *child = [[ZENNode alloc] initWithName:@"child"];
	[parent addChildNode:child];
	[parent addChildNode:child];

	XCTAssertEqual(parent.childCount, 1u);
}

#pragma mark - Root Node

- (void)testRootNodeSingleLevel {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	XCTAssertEqual([root rootNode], root);
}

- (void)testRootNodeMultiLevel {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *mid = [[ZENNode alloc] initWithName:@"mid"];
	ZENNode *leaf = [[ZENNode alloc] initWithName:@"leaf"];
	[root addChildNode:mid];
	[mid addChildNode:leaf];

	XCTAssertEqual([leaf rootNode], root);
	XCTAssertEqual([mid rootNode], root);
}

#pragma mark - Size Propagation

- (void)testSizePropagatesOnAdd {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *childA = [[ZENNode alloc] initWithName:@"a" size:100];
	ZENNode *childB = [[ZENNode alloc] initWithName:@"b" size:200];

	[root addChildNode:childA];
	XCTAssertEqual(root.size, 100);

	[root addChildNode:childB];
	XCTAssertEqual(root.size, 300);
}

- (void)testSizeReducesOnRemove {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *child = [[ZENNode alloc] initWithName:@"child" size:50];
	[root addChildNode:child];
	[root removeChildNode:child];

	XCTAssertEqual(root.size, 0);
}

- (void)testSizePropagatesUpTree {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *mid = [[ZENNode alloc] initWithName:@"mid"];
	[root addChildNode:mid];

	ZENNode *leaf = [[ZENNode alloc] initWithName:@"leaf" size:42];
	[mid addChildNode:leaf];

	XCTAssertEqual(mid.size, 42);
	XCTAssertEqual(root.size, 42);
}

- (void)testFirstChildReplacesLeafSizeInAncestors {
	// A folder listed with a size of its own, like the 4096 bytes a directory takes up
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *folder = [[ZENNode alloc] initWithName:@"folder" size:4096];
	[root addChildNode:folder];
	XCTAssertEqual(root.size, 4096);

	[folder addChildNode:[[ZENNode alloc] initWithName:@"file" size:100]];
	XCTAssertEqual(folder.size, 100);
	XCTAssertEqual(root.size, 100, @"The folder's own size should leave the root's total too");
}

- (void)testFirstChildReplacesLeafSizeAllTheWayUp {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *mid = [[ZENNode alloc] initWithName:@"mid"];
	ZENNode *folder = [[ZENNode alloc] initWithName:@"folder" size:4096];
	[root addChildNode:mid];
	[root addChildNode:[[ZENNode alloc] initWithName:@"sibling" size:10]];
	[mid addChildNode:folder];

	[folder addChildNode:[[ZENNode alloc] initWithName:@"file" size:100]];
	XCTAssertEqual(mid.size, 100);
	XCTAssertEqual(root.size, 110);
}

- (void)testResetSizeUpdatesAncestors {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *folder = [[ZENNode alloc] initWithName:@"folder" size:4096];
	[root addChildNode:folder];

	// Drops the size the empty folder was made with
	[folder resetSize];
	XCTAssertEqual(folder.size, 0);
	XCTAssertEqual(root.size, 0);
}

- (void)testResetSizeKeepsTotalOfChildren {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *folder = [[ZENNode alloc] initWithName:@"folder"];
	[root addChildNode:folder];
	[folder addChildNode:[[ZENNode alloc] initWithName:@"a" size:1]];
	[folder addChildNode:[[ZENNode alloc] initWithName:@"b" size:2]];

	[folder resetSize];
	XCTAssertEqual(folder.size, 3);
	XCTAssertEqual(root.size, 3);
}

- (void)testRemovingLastChildLeavesNoSize {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *folder = [[ZENNode alloc] initWithName:@"folder" size:4096];
	ZENNode *file = [[ZENNode alloc] initWithName:@"file" size:100];
	[root addChildNode:folder];
	[folder addChildNode:file];

	[folder removeChildNode:file];
	XCTAssertEqual(folder.size, 0, @"The folder's own size gave way to its children, and they're gone");
	XCTAssertEqual(root.size, 0);
}

- (void)testMovingSubtreeKeepsTotals {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *left = [[ZENNode alloc] initWithName:@"left"];
	ZENNode *right = [[ZENNode alloc] initWithName:@"right"];
	ZENNode *subtree = [[ZENNode alloc] initWithName:@"subtree"];
	[root addChildNode:left];
	[root addChildNode:right];
	[left addChildNode:subtree];
	[left addChildNode:[[ZENNode alloc] initWithName:@"stays" size:1]];
	[subtree addChildNode:[[ZENNode alloc] initWithName:@"file" size:20]];
	[right addChildNode:[[ZENNode alloc] initWithName:@"other" size:300]];

	[right addChildNode:subtree];
	XCTAssertEqual(left.size, 1);
	XCTAssertEqual(right.size, 320);
	XCTAssertEqual(root.size, 321);
}

- (void)testRandomEditsKeepSizesAddingUp {
	// Seeded, so a failure repeats
	srand48(20261118);
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	NSMutableArray<ZENNode *> *nodes = [NSMutableArray arrayWithObject:root];

	for (NSUInteger step = 0; step < 500; step++) {
		ZENNode *node = nodes[lrand48() % nodes.count];
		switch (lrand48() % 4) {
			case 0:
			case 1: {
				// Add a new node, with a size of its own or none
				NSInteger size = (lrand48() % 3 == 0) ? 0 : lrand48() % 1000;
				ZENNode *added = [[ZENNode alloc] initWithName:[NSString stringWithFormat:@"n%lu", step] size:size];
				[node addChildNode:added];
				[nodes addObject:added];
				break;
			}
			case 2: {
				// Move the node under another, unless that would put it under itself
				ZENNode *target = nodes[lrand48() % nodes.count];
				BOOL underItself = NO;
				for (ZENNode *ancestor = target; ancestor; ancestor = ancestor.parent) {
					underItself = underItself || (ancestor == node);
				}
				if (!underItself) {
					[target addChildNode:node];
				}
				break;
			}
			case 3:
				[node resetSize];
				break;
		}
		[self assertSizesAddUp:root];
		if (self.testRun.failureCount > 0) {
			XCTFail(@"Sizes stopped adding up at step %lu", step);
			return;
		}
	}
}

- (void)testHooksRunWithSizesUpToDate {
	ZENRecordingNode *root = [[ZENRecordingNode alloc] initWithName:@"root"];
	ZENRecordingNode *folder = [[ZENRecordingNode alloc] initWithName:@"folder"];
	ZENNode *file = [[ZENNode alloc] initWithName:@"file" size:42];
	[root addChildNode:folder];
	[folder addChildNode:file];
	[folder removeChildNode:file];

	NSArray *rootCalls = @[@"childWasAdded folder at 0", @"descendantWasAdded file at 42", @"descendantWasRemoved file at 0"];
	NSArray *folderCalls = @[@"childWasAdded file at 42", @"childWasRemoved file at 0"];
	XCTAssertEqualObjects(root.calls, rootCalls);
	XCTAssertEqualObjects(folder.calls, folderCalls);
}

#pragma mark - Counting

- (void)testCountLeaves {
	//       root
	//      /    \
	//    mid     leaf1
	//   /   \
	// leaf2  leaf3
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *mid = [[ZENNode alloc] initWithName:@"mid"];
	ZENNode *leaf1 = [[ZENNode alloc] initWithName:@"leaf1"];
	ZENNode *leaf2 = [[ZENNode alloc] initWithName:@"leaf2"];
	ZENNode *leaf3 = [[ZENNode alloc] initWithName:@"leaf3"];

	[root addChildNode:mid];
	[root addChildNode:leaf1];
	[mid addChildNode:leaf2];
	[mid addChildNode:leaf3];

	XCTAssertEqual([root countLeaves], 3u);
}

- (void)testCountChildrenAndDescendants {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *mid = [[ZENNode alloc] initWithName:@"mid"];
	ZENNode *leaf1 = [[ZENNode alloc] initWithName:@"leaf1"];
	ZENNode *leaf2 = [[ZENNode alloc] initWithName:@"leaf2"];

	[root addChildNode:mid];
	[root addChildNode:leaf1];
	[mid addChildNode:leaf2];

	// Descendants: mid, leaf1, leaf2 = 3
	XCTAssertEqual([root countChildrenAndDescendants], 3u);
}

#pragma mark - Enumeration

- (void)testEnumerateChildren {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *a = [[ZENNode alloc] initWithName:@"a"];
	ZENNode *b = [[ZENNode alloc] initWithName:@"b"];
	[root addChildNode:a];
	[root addChildNode:b];

	NSMutableArray *names = [NSMutableArray new];
	[root enumerateChildrenWithBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		[names addObject:node.name];
	}];

	NSArray *expected = @[@"a", @"b"];
	XCTAssertEqualObjects(names, expected);
}

- (void)testEnumerateChildrenStopFlag {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	[root addChildNode:[[ZENNode alloc] initWithName:@"a"]];
	[root addChildNode:[[ZENNode alloc] initWithName:@"b"]];
	[root addChildNode:[[ZENNode alloc] initWithName:@"c"]];

	NSMutableArray *names = [NSMutableArray new];
	[root enumerateChildrenWithBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		[names addObject:node.name];
		if (index == 0)
			*stop = YES;
	}];

	XCTAssertEqual(names.count, 1u);
}

- (void)testEnumerateParents {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *mid = [[ZENNode alloc] initWithName:@"mid"];
	ZENNode *leaf = [[ZENNode alloc] initWithName:@"leaf"];
	[root addChildNode:mid];
	[mid addChildNode:leaf];

	NSMutableArray *names = [NSMutableArray new];
	[leaf enumerateParentsWithBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		[names addObject:node.name];
	}];

	NSArray *expected = @[@"mid", @"root"];
	XCTAssertEqualObjects(names, expected);
}

- (void)testDepthFirstEnumeration {
	//       root
	//      /    \
	//     a      b
	//    / \
	//   c   d
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *a = [[ZENNode alloc] initWithName:@"a"];
	ZENNode *b = [[ZENNode alloc] initWithName:@"b"];
	ZENNode *c = [[ZENNode alloc] initWithName:@"c"];
	ZENNode *d = [[ZENNode alloc] initWithName:@"d"];
	[root addChildNode:a];
	[root addChildNode:b];
	[a addChildNode:c];
	[a addChildNode:d];

	NSMutableArray *names = [NSMutableArray new];
	[root enumerateDepthFirstUsingBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		[names addObject:node.name];
	}];

	// Post-order: c, d, a, b
	NSArray *expected = @[@"c", @"d", @"a", @"b"];
	XCTAssertEqualObjects(names, expected);
}

- (void)testBreadthFirstEnumeration {
	//       root
	//      /    \
	//     a      b
	//    / \
	//   c   d
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *a = [[ZENNode alloc] initWithName:@"a"];
	ZENNode *b = [[ZENNode alloc] initWithName:@"b"];
	ZENNode *c = [[ZENNode alloc] initWithName:@"c"];
	ZENNode *d = [[ZENNode alloc] initWithName:@"d"];
	[root addChildNode:a];
	[root addChildNode:b];
	[a addChildNode:c];
	[a addChildNode:d];

	NSMutableArray *names = [NSMutableArray new];
	[root enumerateBreadthFirstUsingBlock:^(ZENNode *node, NSUInteger index, BOOL *stop) {
		[names addObject:node.name];
	}];

	NSArray *expected = @[@"a", @"b", @"c", @"d"];
	XCTAssertEqualObjects(names, expected);
}

#pragma mark - Copy

- (void)testCopyCreatesIndependentTree {
	ZENNode *root = [[ZENNode alloc] initWithName:@"root"];
	ZENNode *child = [[ZENNode alloc] initWithName:@"child" size:10];
	[root addChildNode:child];

	ZENNode *copy = [root copy];

	XCTAssertEqualObjects(copy.name, @"root");
	XCTAssertEqual(copy.childCount, 1u);
	XCTAssertEqual(copy.size, 10);

	// Copy should be independent
	XCTAssertNotEqualObjects(copy.nodeID, root.nodeID);

	ZENNode *copiedChild = copy.children.firstObject;
	XCTAssertEqualObjects(copiedChild.name, @"child");
	XCTAssertNotEqual(copiedChild, child);
}

@end
