//
//  RTSPServer.h
//  Encoder Demo
//
//  Created by Geraint Davies on 17/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h> 
#include <sys/socket.h> 
#include <netinet/in.h>

@interface RTSPServer : NSObject

+ (NSString*) getRtspUrl;
+ (RTSPServer*) setupListener;

- (void) onVideoData:(NSArray*) data time:(double) pts;
- (void) shutdownConnection:(id) conn;
- (void) shutdownServer;

@property (readwrite, nonatomic, strong) NSData* sps;
@property (readwrite, nonatomic, strong) NSData* pps;
@property (readwrite, atomic) int bitrate;

@end
