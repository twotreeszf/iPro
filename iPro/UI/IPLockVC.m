//
//  IPLockVC.m
//  iPro
//
//  Created by zhang fan on 15/3/6.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPLockVC.h"

@interface IPLockVC () <MBSliderViewDelegate>

@property (weak, nonatomic) IBOutlet MBSliderView *slider;

@end

@implementation IPLockVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.slider.text = @"Slide to unlock";
    self.slider.animated = NO;
}

- (void) sliderDidSlide:(MBSliderView *)slideView
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
