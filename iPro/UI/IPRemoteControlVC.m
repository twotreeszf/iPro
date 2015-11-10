//
//  IPRemoteControlVC.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPRemoteControlVC.h"
#import "AFNetworking.h"
#import "IPCaptureDataDef.h"
#import "TTImageUtilities.h"

#define kRequestTimeout 2.0

@interface IPRemoteControlVC () <NSNetServiceBrowserDelegate>
{
	__weak IBOutlet UIImageView*	_previewImage;
	__weak IBOutlet UILabel*		_batteryLevelLabel;
	__weak IBOutlet UILabel*		_fpsLabel;
	__weak IBOutlet UIButton*		_recordButton;
	
	AFHTTPSessionManager*		_jsonRequest;
	AFHTTPSessionManager*		_dataReqeust;
	
	volatile IPCaptrueStatus	_status;
	int							_batteryLevel;
	NSTimeInterval				_lastFrameTime;
	int							_frameCount;
	volatile BOOL				_shoudQuit;
    float                       _rotateDegree;
}

@end

@implementation IPRemoteControlVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    	
	_status = CS_Init;
    _rotateDegree = 0.0;
	
	NSURL* URL = [NSURL URLWithString:_serverURL];
	_jsonRequest = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
    [_jsonRequest.requestSerializer setTimeoutInterval:kRequestTimeout];
	
	_dataReqeust = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
    [_dataReqeust.requestSerializer setTimeoutInterval:kRequestTimeout];
	_dataReqeust.responseSerializer = [AFImageResponseSerializer new];
}

- (void)viewDidAppear:(BOOL)animated
{
	_shoudQuit = NO;
	[self refreshStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
	_shoudQuit = YES;
}

- (IBAction)onRecord:(id)sender
{
	if (_status == CS_Running)
	{
		[self startRecording];
	}
	else if (_status == CS_Recording)
	{
		[self stopRecording];
	}
}

- (IBAction)onRotate:(UISegmentedControl *)sender
{
    _rotateDegree = 90.0 * [sender selectedSegmentIndex];
}

- (void)refreshStatus
{
	[_jsonRequest GET:kAPIQueryStatus parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	{
		NSDictionary* dic = (NSDictionary*)responseObject;
		_status = [((NSNumber*)dic[kStatus]) intValue];
		_batteryLevel = [((NSNumber*)dic[kBattery]) intValue];

		[self dealStatus];
	}
	failure:^(NSURLSessionDataTask *task, NSError *error)
	{
		_status = CS_Lost;
		[self dealStatus];
	}];
}

- (void)startCapturing
{
	[_jsonRequest GET:kAPIStartCapturing parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		{
			_status = CS_Running;
			[self dealStatus];
		});
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 _status = CS_Lost;
		 [self dealStatus];
	 }];
}

- (void)stopCapturing
{
	[_jsonRequest GET:kAPIStopCapturing parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 _status = CS_Init;
		 [self dealStatus];
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 _status = CS_Lost;
		 [self dealStatus];
	 }];
}

- (void)fetchPreview
{
	[_dataReqeust GET:kAPIGetPreviewFrame parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 UIImage* frame = (UIImage*)responseObject;
         
         if (_rotateDegree != 0.0)
         {
             CGImageRef rotatedImage = [TTImageUtilities createRotatedImage:frame.CGImage degrees:_rotateDegree];
             frame = [UIImage imageWithCGImage:rotatedImage];
         }
         
         _previewImage.image = frame;
		 
		 [self dealStatus];
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
         {
             [self dealStatus];
         });
	 }];
}

- (void)startRecording
{
	[_jsonRequest GET:kAPIStartRecording parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 _status = CS_Recording;
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 _status = CS_Lost;
		 [self dealStatus];
	 }];
}

- (void)stopRecording
{
	[_jsonRequest GET:kAPIStopRecording parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 _status = CS_Running;
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 _status = CS_Lost;
		 [self dealStatus];
	 }];
}

- (void)dealStatus
{
	// config UI status
    switch (_status)
    {
    case CS_Init:
    case CS_Lost:
        _recordButton.enabled = NO;
        [_recordButton setImage:[UIImage imageNamed:@"CamGrey"] forState:UIControlStateNormal];
		_batteryLevelLabel.text = @"?";
		_fpsLabel.text = @"?";
        break;
    case CS_Running:
	case CS_Recording:
		if (CS_Running == _status)
			[_recordButton setImage:[UIImage imageNamed:@"CamBlue"] forState:UIControlStateNormal];
		else
			[_recordButton setImage:[UIImage imageNamed:@"CamRed"] forState:UIControlStateNormal];

        _recordButton.enabled = YES;
		_batteryLevelLabel.text = [NSString stringWithFormat:@"%02d", _batteryLevel];
			
		NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
		if (_lastFrameTime > 0.0)
		{
			NSTimeInterval frameSpan = timeNow - _lastFrameTime;
			int fps = 1.0 / frameSpan;
			_fpsLabel.text = [NSString stringWithFormat:@"%d", fps];
		}
		_lastFrameTime = timeNow;
        break;

    default:
        break;
    }

	// deal status
    if (!_shoudQuit)
    {
        if (CS_Init == _status)
        {
            [self startCapturing];
        }
        else if ((CS_Running == _status) || (CS_Recording == _status))
        {
			++_frameCount;
			if (_frameCount > 20)
			{
				_frameCount = 0;
				[self refreshStatus];
			}
			else
			{
				[self fetchPreview];
			}
        }
        else if (CS_Lost == _status)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
			{
			   [self refreshStatus];
            });
        }
    }
    else
    {
        if (CS_Running == _status)
		{
			   [self stopCapturing];
		}
    }
}


@end
