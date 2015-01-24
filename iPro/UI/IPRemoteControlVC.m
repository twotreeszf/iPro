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

@interface IPRemoteControlVC ()
{
	__weak IBOutlet UIImageView*	_previewImage;
	__weak IBOutlet UIButton*		_recordButton;
	
	AFHTTPSessionManager* _jsonRequest;
	AFHTTPSessionManager* _dataReqeust;
	
	volatile IPCaptrueStatus _status;
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
	[self refreshStatus];
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
		 [self refreshStatus];
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
		 _previewImage.image = frame;
		 
		 [self refreshStatus];
	 }
	failure:^(NSURLSessionDataTask *task, NSError *error)
	 {
		 _status = CS_Lost;
		 [self dealStatus];
	 }];
}

- (void)dealStatus
{
	if (CS_Init == _status)
	{
		[self startCapturing];
	}
	else if (CS_Running == _status)
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

- (void)startRecording
{
	
}

- (void)stopRecording
{
	
}

@end
