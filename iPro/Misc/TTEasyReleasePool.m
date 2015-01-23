//
//  TTCFEasyRelease.m
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/16.
//
//

#import "TTEasyReleasePool.h"

@implementation TTEasyReleasePool
{
	NSMutableArray* _objs;
}

- (instancetype)init
{
	self = [super init];
	
	_objs = [NSMutableArray new];
	
	return self;
}

- (void)dealloc
{
	for (TTReleaseBlock item in _objs)
	{
		item();
	}
}

- (void)autoreleaseWithBlock:(TTReleaseBlock)block;
{
	[_objs addObject:block];
}

- (void)autoreleaseCFOBJ:(CFTypeRef)obj;
{
	[self autoreleaseWithBlock:^
	{
		CFRelease(obj);
	}];
}

- (void)autoreleaseCOBJ: (void*)obj;
{
	[self autoreleaseWithBlock:^
	{
		free(obj);
	}];
}

@end
