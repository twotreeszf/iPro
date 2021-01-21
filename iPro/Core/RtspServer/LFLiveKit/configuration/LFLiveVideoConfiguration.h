//
//  LFLiveVideoConfiguration.h
//  LFLiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 视频分辨率(都是16：9 当此设备不支持当前分辨率，自动降低一级)
typedef NS_ENUM (NSUInteger, LFLiveVideoSessionPreset){
    LFCaptureSessionPreset576x1024 = 0,
    LFCaptureSessionPreset720x1280,
    LFCaptureSessionPreset1080x1920,
    LFCaptureSessionPreset2160x3840
};

/// 视频质量
typedef NS_ENUM (NSUInteger, LFLiveVideoQuality){
    /// LFCaptureSessionPreset576x1024, fps 25, bitrate 1500kbps
    LFLiveVideoQuality_Low = 0,
    /// LFCaptureSessionPreset720x1280, fps 25, bitrate 2500kbps
    LFLiveVideoQuality_Medium,
    /// LFCaptureSessionPreset1080x1920, fps 25, bitrate 3500kbps
    LFLiveVideoQuality_High,
    /// LFCaptureSessionPreset2160x3840, fps 20, bitrate 5000kbps
    LFLiveVideoQuality_Very_High,
    /// 默认配置
    LFLiveVideoQuality_Default = LFLiveVideoQuality_High
};

@interface LFLiveVideoConfiguration : NSObject<NSCoding, NSCopying>

/// 默认视频配置
+ (instancetype)defaultConfiguration;
/// 视频配置(质量)
+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality;

/// 视频配置(质量 & 是否是横屏)
+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation;

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/// 视频的分辨率，宽高务必设定为 2 的倍数，否则解码播放时可能出现绿边(这个videoSizeRespectingAspectRatio设置为YES则可能会改变)
@property (nonatomic, assign) CGSize videoSize;

/// 输出图像是否等比例,默认为NO
@property (nonatomic, assign) BOOL videoSizeRespectingAspectRatio;

/// 视频输出方向
@property (nonatomic, assign) UIInterfaceOrientation outputImageOrientation;

/// 自动旋转(这里只支持 left 变 right  portrait 变 portraitUpsideDown)
@property (nonatomic, assign) BOOL autorotate;

/// 视频的帧率，即 fps
@property (nonatomic, assign) NSUInteger videoFrameRate;

/// 视频的最大帧率，即 fps
@property (nonatomic, assign) NSUInteger videoMaxFrameRate;

/// 视频的最小帧率，即 fps
@property (nonatomic, assign) NSUInteger videoMinFrameRate;

/// 最大关键帧间隔，可设定为 fps 的2倍，影响一个 gop 的大小
@property (nonatomic, assign) NSUInteger videoMaxKeyframeInterval;

/// 视频的码率，单位是 bps
@property (nonatomic, assign) NSUInteger videoBitRate;

///< 分辨率
@property (nonatomic, assign) LFLiveVideoSessionPreset sessionPreset;

///< ≈sde3分辨率
@property (nonatomic, assign, readonly) NSString *avSessionPreset;

///< 是否是横屏
@property (nonatomic, assign, readonly) BOOL landscape;

@end
