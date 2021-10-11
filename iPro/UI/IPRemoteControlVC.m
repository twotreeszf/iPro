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
#import <IJKMediaFramework/IJKMediaPlayer.h>

#define kRequestTimeout 5.0

@interface IPRemoteControlVC () <NSNetServiceBrowserDelegate>
{
	__weak IBOutlet UIView*	            _videoView;
	__weak IBOutlet UILabel*	        _batteryLevelLabel;
	__weak IBOutlet UIButton*	        _recordButton;
    __weak IBOutlet UIView*             _hudView;
    __weak IBOutlet UISlider*           _expoSlider;
    __weak IBOutlet UILabel*            _expoBiasLabel;
    __weak IBOutlet UISegmentedControl* _rotateControl;
    
	AFHTTPSessionManager*		    _jsonRequest;
	AFHTTPSessionManager*		    _dataReqeust;
    IJKFFMoviePlayerController*     _player;
	
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

- (IBAction)onHud:(id)sender
{
    _hudView.hidden = !_hudView.hidden;
}

- (IBAction)onSlideExpo:(UISlider*)sender
{
    _expoBiasLabel.text = [NSString stringWithFormat:@"%0.1f", sender.value];
}

- (IBAction)onSetExpo:(UISlider *)sender
{
    NSDictionary* params = @{kExpoBias: [NSNumber numberWithFloat:sender.value]};
    [_jsonRequest GET:kAPISetExpoBias parameters:params success:^(NSURLSessionDataTask *task, id responseObject)
    {
        // ok
    }
    failure:^(NSURLSessionDataTask *task, NSError *error)
    {
        _status = CS_Lost;
        [self dealStatus];
    }];
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
        _expoSlider.enabled = NO;
            
        if (_player)
            [self _stopPlay];
        break;
    case CS_Running:
	case CS_Recording:
		if (CS_Running == _status)
			[_recordButton setImage:[UIImage imageNamed:@"CamBlue"] forState:UIControlStateNormal];
		else
			[_recordButton setImage:[UIImage imageNamed:@"CamRed"] forState:UIControlStateNormal];

            _recordButton.enabled = YES;
            _batteryLevelLabel.text = [NSString stringWithFormat:@"%02d", _batteryLevel];
            _expoSlider.enabled = YES;
            
            CGFloat rotateDegree = 90.0 * [_rotateControl selectedSegmentIndex] / 180.0 * M_PI;
            _videoView.transform = CGAffineTransformMakeRotation(rotateDegree);
            _videoView.frame = CGRectMake(0, 0, _videoView.superview.frame.size.width, _videoView.superview.frame.size.height);
            
            if (!_player && _rtspUrl.length)
                [self _startPlay:_rtspUrl];
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
        if (_player)
            [self _stopPlay];
        
        if (CS_Running == _status)
            [self stopCapturing];
    }
}

- (void)_startPlay:(NSString*)url
{
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
    
    IJKFFOptions* options = [IJKFFOptions optionsByDefault];
    
    [options setFormatOptionIntValue:1024 * 16 forKey:@"probesize"];
    [options setFormatOptionIntValue:50000 forKey:@"analyzeduration"];
    
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter"];
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame"];
    
    [options setPlayerOptionIntValue:0 forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:100 forKey:@"max_cached_duration"];
    [options setPlayerOptionIntValue:1 forKey:@"infbuf"];
    [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
    
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURLString:url withOptions:options];
    [_videoView addSubview:_player.view];
    _player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _player.view.frame = _videoView.bounds;
    _player.scalingMode = IJKMPMovieScalingModeAspectFit;
    _player.shouldAutoplay = YES;
    
    [_player prepareToPlay];
}

- (void)_stopPlay
{
    [_player stop];
    [_player shutdown];
    [_player.view removeFromSuperview];
    _player = nil;
}

@end
