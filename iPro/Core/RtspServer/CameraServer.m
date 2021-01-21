//
//  CameraServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraServer.h"
#import "RTSPServer.h"
#import "LFLiveKit/coder/LFHardwareVideoEncoder.h"

static CameraServer* theServer;

@interface CameraServer()<LFVideoEncodingDelegate>
{
    dispatch_queue_t    _streamQueue;
    LFLiveVideoConfiguration* _config;
    id<LFVideoEncoding> _encoder;
    RTSPServer*         _rtsp;
    volatile BOOL       _started;
}
@end


@implementation CameraServer

- (void) startup
{
    NSLog(@"Starting up server");
    
    _rtsp = [RTSPServer setupListener];
    
    _streamQueue = dispatch_queue_create("com.twotrees.ipro.rtspstream", DISPATCH_QUEUE_SERIAL);
    _config = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High outputImageOrientation:UIInterfaceOrientationLandscapeLeft];
    _config.videoFrameRate = 30;
    _config.videoMaxFrameRate = 30;
    _config.videoMinFrameRate = 15;
    _config.videoBitRate = 8 * 1024 * 1024;
    _config.videoMaxKeyframeInterval = 10;
    
    _encoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:_config];
    [_encoder setDelegate:self];
    
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
    
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [_encoder encodeVideoData:pixelBuffer timeStamp:CMTimeGetSeconds(timestamp)*1000];
}

- (void) shutdown
{
    _started = NO;
    
    if (_encoder)
    {
        [ _encoder stopEncoder];
        _encoder = nil;
    }
    
    if (_streamQueue)
    {
        _streamQueue = nil;
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

- (void)videoEncoder:(nullable id<LFVideoEncoding>)encoder videoFrame:(nullable LFVideoFrame *)frame {
    if (!_started)
        return;
    
    NSMutableData* configData = [[NSMutableData alloc] initWithCapacity:frame.sps.length + frame.pps.length];
    [configData appendData:frame.sps];
    [configData appendData:frame.pps];
    
    int bitrate = (int)_encoder.videoBitRate;
    dispatch_async(_streamQueue, ^{
        _rtsp.bitrate = bitrate;
        _rtsp.sps = frame.sps;
        _rtsp.pps = frame.pps;
        [_rtsp onVideoData:@[frame.data] time:(double)frame.timestamp / 1000];
    });
    
}

@end
