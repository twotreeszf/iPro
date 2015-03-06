//
//  IPServiceHostVC.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPServiceHostVC.h"
#import "IPCaptureService.h"
#import "MBSliderView.h"

@interface IPServiceHostVC () <MBSliderViewDelegate>
{
    IPCaptureService* _service;
}

@property (weak, nonatomic) IBOutlet MBSliderView *slider;

@end

@implementation IPServiceHostVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    _service = [IPCaptureService new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];
	
	self.slider.text = @"Slide to unlock";
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_service start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_service stop];
}

- (void)deviceOrientationDidChange
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;

    // Update recording orientation if device changes to portrait or landscape orientation (but not face up/down)
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation))
		_service.recordingOrientation = (AVCaptureVideoOrientation)deviceOrientation;
}

- (void) sliderDidSlide:(MBSliderView *)slideView
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
