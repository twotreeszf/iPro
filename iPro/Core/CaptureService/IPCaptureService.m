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

#define kPreviewFrameWidth		720.0

@interface IPCaptureService() <RosyWriterCapturePipelineDelegate>
{
	GCDWebServer*				_webServer;
	RosyWriterCapturePipeline*	_capture;
	
	NSOperationQueue*			_optQueue;
	NSData*						_lastFrame;
	IPCaptrueStatus				_status;
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
	_lastFrame = nil;
}

- (void)start
{
	BOOL ret = YES;
	{
		NSArray* defaultPorts = @[@80, @88, @8888, @8080];
		for (NSNumber* port in defaultPorts)
		{
			ret = [_webServer startWithPort:[port unsignedIntegerValue] bonjourName:nil];
			if (ret)
				break;
		}
		if (!ret)
			ret = [_webServer startWithPort:0 bonjourName:kServiceName];
		ERROR_CHECK_BOOL(ret);
		
		[_capture startRunning];
		
		_status = CS_Running;
	}
	
Exit0:
	return;
}

- (void)stop
{
	if (CS_Recording == _status)
		[_capture stopRecording];
	_status = CS_Running;
	
	[_capture stopRunning];
	
	[_optQueue cancelAllOperations];
	[_optQueue waitUntilAllOperationsAreFinished];
	_lastFrame = nil;
	
	[_webServer stop];
	
	_status = CS_Init;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Service API

- (GCDWebServerResponse*)queryStatus:(GCDWebServerRequest*)request
{
	return [GCDWebServerDataResponse responseWithJSONObject:@{ kStatus : [NSNumber numberWithInteger:_status] }];
}

- (GCDWebServerResponse*)getPreviewFrame:(GCDWebServerRequest*)request
{
	NSData* lastFrame;
	@synchronized(self)
	{
		lastFrame = _lastFrame;
		_lastFrame = nil;
	}
	
	if (!lastFrame)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"Preivew frame not ready"];
	else
	{
		return [GCDWebServerDataResponse responseWithData:lastFrame contentType:@"application/octet-stream"];
	}
}

- (GCDWebServerResponse*)startRecording:(GCDWebServerRequest*)request
{
	if (CS_Running != _status)
		return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"Capture server is not in running state"];
	else
	{
		NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString* moviePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", time(NULL)]];
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
	CFRetain(previewPixelBuffer);
	
	[_optQueue addOperationWithBlock:^
	{
		TTEasyReleasePool* pool = [TTEasyReleasePool new];
		[pool autoreleaseCFOBJ:previewPixelBuffer];
		
		@synchronized(self)
		{
			if (!_lastFrame)
			{
				UIImage* frame = [TTImageUtilities vImageAspectScaleImage:previewPixelBuffer KeepLongside:kPreviewFrameWidth HighQuality:NO];
				_lastFrame = UIImageJPEGRepresentation(frame, 0.8);
			}
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
