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
#import "GLImage.h"
#import "GLImageView.h"

@interface IPRemoteControlVC ()
{
	
	__weak IBOutlet GLImageView*	_previewImage;
	__weak IBOutlet UIButton*		_recordButton;
	
	AFHTTPSessionManager* _jsonRequest;
	AFHTTPSessionManager* _dataReqeust;
	
	volatile IPCaptrueStatus	_status;
	volatile BOOL				_shoudQuit;
}

@end

@implementation IPRemoteControlVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_status = CS_Init;
	_serverURL = @"http://192.168.136.42/";
	
	NSURL* URL = [NSURL URLWithString:_serverURL];
	_jsonRequest = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
	
	_dataReqeust = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
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

- (void)refreshStatus
{
	[_jsonRequest GET:kAPIQueryStatus parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	{
		 NSDictionary* dic = (NSDictionary*)responseObject;
		 _status = [((NSNumber*)dic[kStatus]) intValue];

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
		 _status = CS_Running;
		 [self dealStatus];
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
		 _previewImage.image = [GLImage imageWithUIImage:frame];
		 
		 [self refreshStatus];
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 if (error.code != NSURLErrorBadServerResponse)
		 {
			 _status = CS_Lost;
			 [self dealStatus];			 
		 }
	 }];
}

- (void)startRecording
{
	[_jsonRequest GET:kAPIStartRecording parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	 {
		 _status = CS_Recording;
		 [self dealStatus];
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
		 [self dealStatus];
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 _status = CS_Lost;
		 [self dealStatus];
	 }];
}

- (void)dealStatus
{
	// config button status
    switch (_status)
    {
    case CS_Init:
    case CS_Lost:
        _recordButton.enabled = NO;
        _recordButton.titleLabel.textColor = [UIColor lightGrayColor];
        break;
    case CS_Running:
        _recordButton.enabled = YES;
        _recordButton.titleLabel.textColor = [UIColor blueColor];
        break;
    case CS_Recording:
        _recordButton.enabled = YES;
        _recordButton.titleLabel.textColor = [UIColor redColor];
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
            [self fetchPreview];
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
		if (CS_Recording == _status)
		{
			[self stopRecording];
		}
		else if (CS_Running == _status)
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
		   {
			   [self stopCapturing];
		   });
		}
    }
}


@end
