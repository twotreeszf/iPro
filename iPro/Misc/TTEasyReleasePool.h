//
//  TTCFEasyRelease.h
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/16.
//
//

#import <Foundation/Foundation.h>

typedef void (^TTReleaseBlock)();

@interface TTEasyReleasePool : NSObject

- (void)autoreleaseWithBlock:(TTReleaseBlock)block;
- (void)autoreleaseCFOBJ:(CFTypeRef)obj;
- (void)autoreleaseCOBJ:(void*)obj;

@end
