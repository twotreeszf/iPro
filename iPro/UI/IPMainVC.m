//
//  IPMainVC.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPMainVC.h"

@interface IPMainVC ()

@end

@implementation IPMainVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationBar* bar = self.navigationController.navigationBar;
    [bar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [bar setShadowImage:[[UIImage alloc] init]];
    [bar setTranslucent:YES];
}

@end
