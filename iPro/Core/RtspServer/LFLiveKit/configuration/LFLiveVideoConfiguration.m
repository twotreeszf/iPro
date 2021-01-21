//
//  LFLiveVideoConfiguration.m
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LFLiveVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>


@implementation LFLiveVideoConfiguration

#pragma mark -- LifeCycle

+ (instancetype)defaultConfiguration {
    LFLiveVideoConfiguration *configuration = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_Default];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality {
    LFLiveVideoConfiguration *configuration = [LFLiveVideoConfiguration defaultConfigurationForQuality:videoQuality outputImageOrientation:UIInterfaceOrientationPortrait];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation {
    LFLiveVideoConfiguration *configuration = [LFLiveVideoConfiguration new];
    switch (videoQuality) {
    case LFLiveVideoQuality_Low:{
        configuration.sessionPreset = LFCaptureSessionPreset576x1024;
        configuration.videoFrameRate = 25;
        configuration.videoMaxFrameRate = 25;
        configuration.videoMinFrameRate = 15;
        configuration.videoBitRate = 1500 * 1000;
        configuration.videoSize = CGSizeMake(576, 1024);
    }
        break;
    case LFLiveVideoQuality_Medium:{
        configuration.sessionPreset = LFCaptureSessionPreset720x1280;
        configuration.videoFrameRate = 25;
        configuration.videoMaxFrameRate = 25;
        configuration.videoMinFrameRate = 15;
        configuration.videoBitRate = 2500 * 1000;
        configuration.videoSize = CGSizeMake(720, 1280);
    }
        break;
    case LFLiveVideoQuality_High: {
        configuration.sessionPreset = LFCaptureSessionPreset1080x1920;
        configuration.videoFrameRate = 25;
        configuration.videoMaxFrameRate = 25;
        configuration.videoMinFrameRate = 15;
        configuration.videoBitRate = 3500 * 1000;
        configuration.videoSize = CGSizeMake(1080, 1920);
    }
        break;
    case LFLiveVideoQuality_Very_High:{
        configuration.sessionPreset = LFCaptureSessionPreset2160x3840;
        configuration.videoFrameRate = 20;
        configuration.videoMaxFrameRate = 20;
        configuration.videoMinFrameRate = 10;
        configuration.videoBitRate = 5000 * 1000;
        configuration.videoSize = CGSizeMake(2160, 3840);
    }
        break;
            
    default:
        break;
    }
    configuration.sessionPreset = [configuration supportSessionPreset:configuration.sessionPreset];
    configuration.videoMaxKeyframeInterval = configuration.videoFrameRate*2;
    configuration.outputImageOrientation = outputImageOrientation;
    CGSize size = configuration.videoSize;
    if(configuration.landscape) {
        configuration.videoSize = CGSizeMake(size.height, size.width);
    } else {
        configuration.videoSize = CGSizeMake(size.width, size.height);
    }
    return configuration;
    
}

#pragma mark -- Setter Getter
- (NSString *)avSessionPreset {
    NSString *avSessionPreset = nil;
    switch (self.sessionPreset) {
    case LFCaptureSessionPreset576x1024:{
        avSessionPreset = AVCaptureSessionPreset1280x720;
    }
        break;
    case LFCaptureSessionPreset720x1280:{
        avSessionPreset = AVCaptureSessionPresetiFrame1280x720;
    }
        break;
    case LFCaptureSessionPreset1080x1920:{
        avSessionPreset = AVCaptureSessionPreset1920x1080;
    }
        break;
    case LFCaptureSessionPreset2160x3840:{
        avSessionPreset = AVCaptureSessionPreset3840x2160;
    }
        break;

    default: {
        avSessionPreset = AVCaptureSessionPresetiFrame1280x720;
    }
        break;
    }
    return avSessionPreset;
}

- (BOOL)landscape{
    return (self.outputImageOrientation == UIInterfaceOrientationLandscapeLeft || self.outputImageOrientation == UIInterfaceOrientationLandscapeRight) ? YES : NO;
}

- (CGSize)videoSize{
    if(_videoSizeRespectingAspectRatio){
        return self.aspectRatioVideoSize;
    }
    return _videoSize;
}

- (void)setVideoMaxFrameRate:(NSUInteger)videoMaxFrameRate {
    if (videoMaxFrameRate <= _videoFrameRate) return;
    _videoMaxFrameRate = videoMaxFrameRate;
}

- (void)setVideoMinFrameRate:(NSUInteger)videoMinFrameRate {
    if (videoMinFrameRate >= _videoFrameRate) return;
    _videoMinFrameRate = videoMinFrameRate;
}

- (void)setSessionPreset:(LFLiveVideoSessionPreset)sessionPreset{
    _sessionPreset = sessionPreset;
    _sessionPreset = [self supportSessionPreset:sessionPreset];
}

#pragma mark -- Custom Method
- (LFLiveVideoSessionPreset)supportSessionPreset:(LFLiveVideoSessionPreset)sessionPreset {
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *inputCamera;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices){
        if ([device position] == AVCaptureDevicePositionFront){
            inputCamera = device;
        }
    }
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if ([session canAddInput:videoInput]){
        [session addInput:videoInput];
    }
    
    if (![session canSetSessionPreset:self.avSessionPreset]) {
        sessionPreset -= 1;
    }
    return sessionPreset;
}

- (CGSize)captureOutVideoSize{
    CGSize videoSize = CGSizeZero;
    switch (_sessionPreset) {
        case LFCaptureSessionPreset576x1024:{
            videoSize = CGSizeMake(576, 1024);
        }
            break;
        case LFCaptureSessionPreset720x1280:{
            videoSize = CGSizeMake(720, 1280);
        }
            break;
        case LFCaptureSessionPreset1080x1920:{
            videoSize = CGSizeMake(1080, 1920);
        }
            break;
        case LFCaptureSessionPreset2160x3840:{
            videoSize = CGSizeMake(2160, 3840);
        }
            break;
            
        default:{
            videoSize = CGSizeMake(720, 1280);
        }
            break;
    }
    
    if (self.landscape){
        return CGSizeMake(videoSize.height, videoSize.width);
    }
    return videoSize;
}

- (CGSize)aspectRatioVideoSize{
    CGSize size = AVMakeRectWithAspectRatioInsideRect(self.captureOutVideoSize, CGRectMake(0, 0, _videoSize.width, _videoSize.height)).size;
    NSInteger width = ceil(size.width);
    NSInteger height = ceil(size.height);
    if(width %2 != 0) width = width - 1;
    if(height %2 != 0) height = height - 1;
    return CGSizeMake(width, height);
}


@end
