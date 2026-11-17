//
//  NodeTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

@interface NodeTests : XCTestCase

@end

@implementation NodeTests

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
		if (index == 0) *stop = YES;
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
