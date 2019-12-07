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
#import <MobileVLCKit/MobileVLCKit.h>

#define kRequestTimeout 2.0

@interface IPRemoteControlVC () <NSNetServiceBrowserDelegate>
{
	__weak IBOutlet UIView*	            _videoView;
	__weak IBOutlet UILabel*	        _batteryLevelLabel;
	__weak IBOutlet UIButton*	        _recordButton;
    __weak IBOutlet UISegmentedControl* _rotateControl;
    
	AFHTTPSessionManager*		_jsonRequest;
	AFHTTPSessionManager*		_dataReqeust;
    
    VLCMediaPlayer*             _player;
	
	volatile IPCaptrueStatus	_status;
	int							_batteryLevel;
    NSString*                   _rtspUrl;
	volatile BOOL				_shoudQuit;
    float                       _rotateDegree;
}

@end

@implementation IPRemoteControlVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    	
	_status = CS_Init;
    _videoView.translatesAutoresizingMaskIntoConstraints = NO;
	
    // request client
	NSURL* URL = [NSURL URLWithString:_serverURL];
	_jsonRequest = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
    [_jsonRequest.requestSerializer setTimeoutInterval:kRequestTimeout];
	
	_dataReqeust = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
    [_dataReqeust.requestSerializer setTimeoutInterval:kRequestTimeout];
	_dataReqeust.responseSerializer = [AFImageResponseSerializer new];

    // vlc player
    _player = [[VLCMediaPlayer alloc] initWithOptions:nil];
    _player.drawable = _videoView;
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
    [self dealStatus];
}

- (void)refreshStatus
{
	[_jsonRequest GET:kAPIQueryStatus parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
	{
		NSDictionary* dic = (NSDictionary*)responseObject;
		_status = [((NSNumber*)dic[kStatus]) intValue];
		_batteryLevel = [((NSNumber*)dic[kBattery]) intValue];
        _rtspUrl = dic[kRtspServer];

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
        break;
    case CS_Running:
	case CS_Recording:
		if (CS_Running == _status)
			[_recordButton setImage:[UIImage imageNamed:@"CamBlue"] forState:UIControlStateNormal];
		else
			[_recordButton setImage:[UIImage imageNamed:@"CamRed"] forState:UIControlStateNormal];

            _recordButton.enabled = YES;
            _batteryLevelLabel.text = [NSString stringWithFormat:@"%02d", _batteryLevel];
            
            CGFloat rotateDegree = 90.0 * [_rotateControl selectedSegmentIndex] / 180.0 * M_PI;
            _videoView.transform = CGAffineTransformMakeRotation(rotateDegree);
            _videoView.frame = CGRectMake(0, 0, _videoView.superview.frame.size.width, _videoView.superview.frame.size.height);
                
            if (!(_player.playing || _player.willPlay))
            {
                if (_rtspUrl.length)
                {
                    _player.media = [VLCMedia mediaWithURL:[NSURL URLWithString:_rtspUrl]];
                    [_player play];
                }
            }
            
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
        else if ((CS_Running == _status) || (CS_Recording == _status) || (CS_Lost == _status))
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
            {
               [self refreshStatus];
            });
        }
    }
    else
    {
        if ((_player.playing || _player.willPlay))
            [_player stop];
        
        if (CS_Running == _status)
            [self stopCapturing];
    }
}

@end
