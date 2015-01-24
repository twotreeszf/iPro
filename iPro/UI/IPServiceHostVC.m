//
//  IPServiceHostVC.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPServiceHostVC.h"
#import "IPCaptureService.h"

@interface IPServiceHostVC ()
{
	IPCaptureService* _service;
}

@end

@implementation IPServiceHostVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
	_service = [IPCaptureService new];
}

- (void)viewWillAppear:(BOOL)animated
{
	[_service start];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_service stop];
}

@end
