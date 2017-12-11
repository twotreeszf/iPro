//
//  IPMainVC.m
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPMainVC.h"
#import "IPHelper.h"

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
    
    // request all permissions
    [IPHelper requestPhotoLibraryAuthorization:^(BOOL success)
    {
        if (!success)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Photo pimission is not granted" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    [IPHelper requestCameraAuthorization:^(BOOL success)
    {
        if (!success)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Camera pimission is not granted" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    [IPHelper requestMicrophoneAuthorization:^(BOOL success)
    {
        if (!success)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Microphone pimission is not granted" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

@end
