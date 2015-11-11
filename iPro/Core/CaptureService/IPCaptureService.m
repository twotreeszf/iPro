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

#define kPreviewFrameWidth		240.0
#define kMaxPreviewFrameCount   6

@interface IPCaptureService() <RosyWriterCapturePipelineDelegate>
{
	GCDWebServer*				_webServer;
	RosyWriterCapturePipeline*	_capture;
	
	NSOperationQueue*			_optQueue;
    NSMutableArray*             _frameQueue;
	IPCaptrueStatus				_status;
}

@end

@implementation IPCaptureService

- (instancetype)init
{
	self = [super init];
    
    _frameQueue = [NSMutableArray new];
	
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
	
	[_webServer addHandlerForMethod:@"GET" path:kAPIGetPreviewFrame requestClass:[GCDWebServerRequest class] processBlock:^
	 GCDWebServerResponse *(GCDWebServerRequest *request)
	 {
		 return [service getPreviewFrame:request];
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
	
	// capture service
	_optQueue = [NSOperationQueue new];
	_optQueue.maxConcurrentOperationCount = 1;
	
	_capture = [RosyWriterCapturePipeline new];
	[_capture setDelegate:self callbackQueue:dispatch_get_main_queue()];
	
	return self;
}

- (void)dealloc
{
	_optQueue = nil;
	_capture = nil;
	_status = CS_Init;
	_webServer = nil;
    _frameQueue = nil;
}

- (void)setRecordingOrientation:(AVCaptureVideoOrientation)recordingOrientation
{
	_capture.recordingOrientation = recordingOrientation;
}

- (void)start
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
	return;
}

- (void)stop
{
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
	
	[_optQueue cancelAllOperations];
	[_optQueue waitUntilAllOperationsAreFinished];
	_frameQueue = nil;
	
	[_webServer stop];
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Service API

- (GCDWebServerResponse*)queryStatus:(GCDWebServerRequest*)request
{
	NSNumber* batteryLevel = [NSNumber numberWithInt:[UIDevice currentDevice].batteryLevel * 100];
	return [GCDWebServerDataResponse responseWithJSONObject:@{
															  kStatus : [NSNumber numberWithInt:_status],
															  kBattery: batteryLevel
															  }];
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

- (GCDWebServerResponse*)getPreviewFrame:(GCDWebServerRequest*)request
{
	NSData* frame;
	@synchronized(self)
	{
        frame = [_frameQueue dequeue];
	}
	
	if (!frame)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"Preivew frame not ready"];
	else
	{
		return [GCDWebServerDataResponse responseWithData:frame contentType:@"image/jpeg"];
	}
}

- (GCDWebServerResponse*)startRecording:(GCDWebServerRequest*)request
{
	if (CS_Running != _status)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not in running state"];
	else
	{
		NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString* moviePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.mov", time(NULL)]];
		[_capture startRecordingWithURL:[NSURL fileURLWithPath:moviePath]];
		
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

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Capture Delegate

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline didStopRunningWithError:(NSError*)error
{
	
}

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline previewPixelBufferReadyForDisplay:(CVPixelBufferRef)previewPixelBuffer
{
	@synchronized(self)
	{
		if ((_frameQueue.count + _optQueue.operationCount) >= kMaxPreviewFrameCount)
			return;
	}
	
	CFRetain(previewPixelBuffer);
	
	[_optQueue addOperationWithBlock:^
	{
		TTEasyReleasePool* pool = [TTEasyReleasePool new];
		[pool autoreleaseCFOBJ:previewPixelBuffer];
        
        UIImage* frame = [TTImageUtilities aspectScaleImage:previewPixelBuffer KeepLongside:kPreviewFrameWidth];
        NSData* data = UIImageJPEGRepresentation(frame, 0.9);
        
        @synchronized(self)
        {
            [_frameQueue enqueue:data];
        }
	}];
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
	
}

@end
