//
//  IPHelper.m
//  iPro
//
//  Created by fanzhang on 2017/12/11.
//  Copyright © 2017年 twotrees. All rights reserved.
//

#import "IPHelper.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

@implementation IPHelper

+ (void)requestPhotoLibraryAuthorization:(BoolResultBlock)resultBlock
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusAuthorized == status)
        resultBlock(YES);
    else if (PHAuthorizationStatusNotDetermined == status)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
         {
             if (PHAuthorizationStatusAuthorized == status)
                 resultBlock(YES);
             else
                 resultBlock(NO);
         }];
    }
    else
        resultBlock(NO);
}

+ (void)requestCameraAuthorization:(BoolResultBlock)resultBlock
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (AVAuthorizationStatusAuthorized == status)
        resultBlock(YES);
    else if (AVAuthorizationStatusNotDetermined == status)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
        {
            resultBlock(granted);
        }];
    }
    else
        resultBlock(NO);
}

+ (void)requestMicrophoneAuthorization:(BoolResultBlock)resultBlock
{
    AVAudioSessionRecordPermission status = [[AVAudioSession sharedInstance] recordPermission];
    if (AVAudioSessionRecordPermissionGranted == status)
        resultBlock(YES);
    else if (AVAudioSessionRecordPermissionUndetermined == status)
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted)
        {
            resultBlock(granted);
        }];
    }
    else
        resultBlock(NO);
}


@end
