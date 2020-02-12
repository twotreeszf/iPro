//
//  IPCaptureService.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPCaptureService.h"
#import "GCDWebServer.h"
#import "IPCaptureDataDef.h"
#import "RosyWriterCapturePipeline.h"
#import "GCDWebServerErrorResponse.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerFileStreamResponse.h"
#import "GCDWebServerFileResponse.h"
#import "TTImageUtilities.h"
#import "PHAsset+Utility.h"
#import "AFNetworking.h"

#define kPreviewFrameWidth		240.0
#define kMaxPreviewFrameCount   6
#define kFileRollingFrames      (30 * 60 * 30)

@interface IPCaptureService() <RosyWriterCapturePipelineDelegate>
{
	GCDWebServer*				_webServer;
	RosyWriterCapturePipeline*	_capture;
	
	IPCaptrueStatus				_status;
    NSString*                   _currentFilePath;
    BOOL                        _isRollingFile;
    NSUInteger                  _currentFrames;
}

@end

@implementation IPCaptureService

- (instancetype)init
{
	self = [super init];
	
	// web service
	_webServer = [GCDWebServer new];
	IPCaptureService* __weak service = self;
	
	[_webServer addHandlerForMethod:@"GET" path:kAPIQueryStatus requestClass:[GCDWebServerRequest class] processBlock:^
	 GCDWebServerResponse *(GCDWebServerRequest *request)
	{
		return [service queryStatus:request];
	}];
	
	[_webServer addHandlerForMethod:@"GET" path:kAPIStartCapturing requestClass:[GCDWebServerRequest class] processBlock:^
	 GCDWebServerResponse *(GCDWebServerRequest *request)
	 {
		 return [service startCapturing:request];
	 }];
	
	[_webServer addHandlerForMethod:@"GET" path:kAPIStopCapturing requestClass:[GCDWebServerRequest class] processBlock:^
	 GCDWebServerResponse *(GCDWebServerRequest *request)
	 {
		 return [service stopCapturing:request];
	 }];
		
	[_webServer addHandlerForMethod:@"GET" path:kAPIStartRecording requestClass:[GCDWebServerRequest class] processBlock:^
	 GCDWebServerResponse *(GCDWebServerRequest *request)
	 {
		 return [service startRecording:request];
	 }];
	
	[_webServer addHandlerForMethod:@"GET" path:kAPIStopRecording requestClass:[GCDWebServerRequest class] processBlock:^
	 GCDWebServerResponse *(GCDWebServerRequest *request)
	 {
		 return [service stopRecording:request];
	 }];
    
    [_webServer addHandlerForMethod:@"GET" path:kAPISetExpoBias requestClass:[GCDWebServerRequest class] processBlock:^
    GCDWebServerResponse *(GCDWebServerRequest *request)
    {
        return [service setExpoBias:request];
    }];
		
	_capture = [RosyWriterCapturePipeline new];
	[_capture setDelegate:self callbackQueue:dispatch_get_main_queue()];
	
	return self;
}

- (void)dealloc
{
	_capture = nil;
	_status = CS_Init;
	_webServer = nil;
}

- (void)setRecordingOrientation:(AVCaptureVideoOrientation)recordingOrientation
{
	_capture.recordingOrientation = recordingOrientation;
}

- (void)start
{
    [self _startWebServer];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyNetworkChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    });
}

- (void)stop
{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	if (CS_Recording == _status)
	{
		[_capture stopRecording];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
		
		_status = CS_Running;
	}
	
	if (CS_Running == _status)
	{
		[_capture stopRunning];
		_status = CS_Init;
	}
	
	[_webServer stop];
}

- (void)onNotifyNetworkChange:(NSNotification*)notification
{
    AFNetworkReachabilityStatus status = ((NSNumber*)notification.userInfo[AFNetworkingReachabilityNotificationStatusItem]).integerValue ;
    if (AFNetworkReachabilityStatusReachableViaWiFi == status)
    {
        [self _stopWebServer];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self _startWebServer];
        });
    }
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Service API

- (GCDWebServerResponse*)queryStatus:(GCDWebServerRequest*)request
{
    NSMutableDictionary* dic = [NSMutableDictionary new];
    dic[kStatus] = [NSNumber numberWithInt:(int)_status];
    dic[kBattery] = [NSNumber numberWithInt:[UIDevice currentDevice].batteryLevel * 100];
    
    NSString* rtspUrl = _capture.rtspServerUrl;
    if (rtspUrl.length)
        dic[kRtspServer] = rtspUrl;
    
	return [GCDWebServerDataResponse responseWithJSONObject:dic];
}

- (GCDWebServerResponse*)startCapturing:(GCDWebServerRequest*)request
{
	if (CS_Init != _status)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not in init state"];
	else
	{
		[_capture startRunning];
		_status = CS_Running;
		
		return [GCDWebServerDataResponse responseWithJSONObject:@{ kResult : kOK}];
	}
}

- (GCDWebServerResponse*)stopCapturing:(GCDWebServerRequest*)request
{
	if (CS_Running != _status)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not in running state"];
	else
	{
		[_capture stopRunning];
		_status = CS_Init;
		
		return [GCDWebServerDataResponse responseWithJSONObject:@{ kResult : kOK}];
	}
}

- (GCDWebServerResponse*)startRecording:(GCDWebServerRequest*)request
{
	if (CS_Running != _status)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not in running state"];
	else
	{
        [self _startRecording];
		_status = CS_Recording;
		
		return [GCDWebServerDataResponse responseWithJSONObject:@{ kResult : kOK}];
	}
}

- (GCDWebServerResponse*)stopRecording:(GCDWebServerRequest*)request
{
	if (CS_Recording != _status)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not in recording state"];
	else
	{
		[_capture stopRecording];
		_status = CS_Running;
		
		return [GCDWebServerDataResponse responseWithJSONObject:@{ kResult : kOK}];
	}
}

- (GCDWebServerResponse*)setExpoBias:(GCDWebServerRequest*)request
{
    if (CS_Init == _status)
        return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not inited"];
    else
    {
        float expoBias = ((NSNumber*)request.query[kExpoBias]).floatValue;
        [_capture setExposureTargetBias:expoBias];
        
        return [GCDWebServerDataResponse responseWithJSONObject:@{ kResult : kOK}];
    }
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Capture Delegate

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline didStopRunningWithError:(NSError*)error
{
	
}

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline previewPixelBufferReadyForDisplay:(CVPixelBufferRef)previewPixelBuffer
{
    // deal file rolling
    if (++_currentFrames >= kFileRollingFrames && !_isRollingFile)
    {
        _isRollingFile = YES;
        [_capture stopRecording];
    }
}

- (void)capturePipelineDidRunOutOfPreviewBuffers:(RosyWriterCapturePipeline*)capturePipeline
{
	
}

- (void)capturePipelineRecordingDidStart:(RosyWriterCapturePipeline*)capturePipeline
{
	
}

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline recordingDidFailWithError:(NSError*)error
{
	
}

- (void)capturePipelineRecordingWillStop:(RosyWriterCapturePipeline*)capturePipeline
{
	
}

- (void)capturePipelineRecordingDidStop:(RosyWriterCapturePipeline*)capturePipeline
{
    [self _saveFileToPhotoLibrary:_currentFilePath];
    _currentFilePath = nil;
    _currentFrames = 0;
    
    if (_isRollingFile)
        [self _startRecording];
    
    _isRollingFile = NO;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void)_startRecording
{
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* moviePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.mov", time(NULL)]];
    [_capture startRecordingWithURL:[NSURL fileURLWithPath:moviePath]];
    _currentFilePath = moviePath;
}

- (void)_saveFileToPhotoLibrary:(NSString*)filePath
{
    [PHAsset saveVideoAtURL:[NSURL fileURLWithPath:filePath] location:nil completionBlock:^(PHAsset *asset, BOOL success)
    {
        if (success)
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            [asset saveToAlbum:@"iPro-Movie" completionBlock:^(BOOL success)
            {
                ;
            }];
        }
    }];
}

- (BOOL)_startWebServer
{
    BOOL ret = YES;
    {
        NSArray* defaultPorts = @[@80, @88, @8888, @8080];
        for (NSNumber* port in defaultPorts)
        {
            NSMutableDictionary* options = [NSMutableDictionary dictionary];
            [options setObject:port forKey:GCDWebServerOption_Port];
            [options setValue:kServiceName forKey:GCDWebServerOption_BonjourName];
            [options setValue:kServiceType forKey:GCDWebServerOption_BonjourType];
            
            ret = [_webServer startWithOptions:options error:NULL];
            if (ret)
                break;
        }
        ERROR_CHECK_BOOL(ret);
    }
    
Exit0:
    return ret;
}

- (void)_stopWebServer
{
    [_webServer stop];
}

@end
