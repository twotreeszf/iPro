//
//  IPServiceHostVC.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPServiceHostVC.h"
#import "RosyWriterCapturePipeline.h"

@interface IPServiceHostVC () <RosyWriterCapturePipelineDelegate>
{
    RosyWriterCapturePipeline*	_capture;
	NSOperationQueue*			_optQueue;
	BOOL						_orientationSetuped;
}

@property (weak, nonatomic) IBOutlet UIImageView* previewImage;

@end

@implementation IPServiceHostVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    _capture = [RosyWriterCapturePipeline new];
	[_capture setDelegate:self callbackQueue:dispatch_get_main_queue()];
	
	_optQueue = [NSOperationQueue new];
}

- (IBAction)onRecord:(id)sender
{
    [_capture startRunning];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[_capture startRecording];
    });
}

- (IBAction)onStop:(id)sender
{
    [_capture stopRecording];
    [_capture stopRunning];
	
	_orientationSetuped = NO;
}

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline didStopRunningWithError:(NSError*)error
{
}

- (void)capturePipeline:(RosyWriterCapturePipeline*)capturePipeline previewPixelBufferReadyForDisplay:(CVPixelBufferRef)previewPixelBuffer
{
	CFRetain(previewPixelBuffer);

	[_optQueue cancelAllOperations];
	[_optQueue addOperationWithBlock:^
	{
		TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];
		[pool autorelease:previewPixelBuffer];
		
		int w = CVPixelBufferGetWidth(previewPixelBuffer);
		int h = CVPixelBufferGetHeight(previewPixelBuffer);
		
		UIGraphicsBeginImageContext(CGSizeMake(w, h));
		
		CGContextRef c = UIGraphicsGetCurrentContext();
		unsigned char* data = CGBitmapContextGetData(c);
		if (data != NULL)
		{
			CVPixelBufferLockBaseAddress(previewPixelBuffer, 0);
			unsigned char* buffer = CVPixelBufferGetBaseAddress(previewPixelBuffer);
			memcpy(data, buffer, w * h * 4);
			
			CVPixelBufferUnlockBaseAddress(previewPixelBuffer, 0);
		}
		
		UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
		
		UIGraphicsEndImageContext();
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^
		 {
			 if (!_orientationSetuped)
			 {
				 UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
				 _previewImage.transform = [_capture transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation
																					withAutoMirroring:YES];
				 _orientationSetuped = YES;
			 }
			 
			 _previewImage.image = img;
		 }];
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
