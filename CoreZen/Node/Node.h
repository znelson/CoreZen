//
//  Node.h
//  CoreZen
//
//  Created by Zach Nelson on 7/20/22.
//

#import <Foundation/Foundation.h>

@class ZENNode;
typedef void (^ZENNodeEnumerateBlock)(id node, NSUInteger index, BOOL *stop);

@interface ZENNode : NSObject

@property (nonatomic, readonly, strong) NSUUID *nodeID;

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly) NSInteger size;

@property (nonatomic, readonly, weak) ZENNode *parent;
@property (nonatomic, readonly, strong) NSArray<ZENNode *> *children;

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name
						size:(NSInteger)size;

- (id)rootNode;

- (void)addChildNode:(id)child;
- (void)removeChildNode:(id)child;

- (void)copyChildren:(id)node;

- (void)childWasAdded:(id)child;
- (void)childWasRemoved:(id)child;

- (void)descendentWasAdded:(id)descendent;
- (void)descendentWasRemoved:(id)descendent;

- (void)resetSize;

- (void)enumerateChildrenWithBlock:(ZENNodeEnumerateBlock)block;
- (void)enumerateParentsWithBlock:(ZENNodeEnumerateBlock)block;

- (void)enumerateDepthFirstUsingBlock:(ZENNodeEnumerateBlock)block;
- (void)enumerateBreadthFirstUsingBlock:(ZENNodeEnumerateBlock)block;

@end