//
//  CameraServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraServer.h"
#import "AVEncoder.h"
#import "RTSPServer.h"

static CameraServer* theServer;

@interface CameraServer()
{
    dispatch_queue_t    _encodeQueue;
    AVEncoder*          _encoder;
    RTSPServer*         _rtsp;
    volatile BOOL       _started;
}
@end


@implementation CameraServer

- (void) startup
{
    NSLog(@"Starting up server");
        
    // create an output for YUV output with self as delegate
    _encodeQueue = dispatch_queue_create("uk.co.gdcl.avencoder.capture", DISPATCH_QUEUE_SERIAL);
    
    // create an encoder
    _encoder = [AVEncoder encoderForHeight:720 andWidth:1280];
    [_encoder encodeWithBlock:^int(NSArray* data, double pts) {
        if (_rtsp != nil)
        {
            _rtsp.bitrate = _encoder.bitspersecond;
            [_rtsp onVideoData:data time:pts];
        }
        return 0;
    } onParams:^int(NSData *data) {
        _rtsp = [RTSPServer setupListener:data];
        return 0;
    }];
    
    _started = YES;
}

- (BOOL)started
{
    return _started;
}

- (void) encodeFrame:(CMSampleBufferRef)sampleBuffer
{
    if (!_started)
        return;
    
    // pass frame to encoder
    CFRetain(sampleBuffer);
    dispatch_async(_encodeQueue, ^
    {
        [_encoder encodeFrame:sampleBuffer];
        CFRelease(sampleBuffer);
    });
}

- (void) shutdown
{
    _started = NO;
    
    if (_encodeQueue)
    {
        _encodeQueue = nil;
    }
    
    if (_encoder)
    {
        [ _encoder shutdown];
        _encoder = nil;
    }
    
    if (_rtsp)
    {
        [_rtsp shutdownServer];
        _rtsp = nil;
    }
}

- (NSString*) getURL
{
    NSString* ipaddr = [RTSPServer getIPAddress];
    NSString* url = [NSString stringWithFormat:@"rtsp://%@/", ipaddr];
    return url;
}

@end
