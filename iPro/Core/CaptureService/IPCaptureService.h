//
//  IPCaptureService.h
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface IPCaptureService : NSObject

@property (nonatomic, assign) AVCaptureVideoOrientation recordingOrientation;

- (void)start;
- (void)stop;

@end
