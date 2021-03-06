//
//  TTImageUtilities.h
//  iPro
//
//  Created by zhang fan on 15/1/22.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTImageUtilities : NSObject

+ (UIImage*)imageFromPixelBuffer:(CVPixelBufferRef)sourceImage;

+ (UIImage*)aspectScaleImage:(CVPixelBufferRef)sourceImage KeepShortside:(CGFloat)shortside;
+ (UIImage*)aspectScaleImage:(CVPixelBufferRef)sourceImage KeepLongside:(CGFloat)longside;
+ (UIImage*)scaleImage:(CVPixelBufferRef)sourceImage WithSize:(CGSize)destSize;

+ (UIImage*)vImageAspectScaleImage:(CVPixelBufferRef)sourceImage KeepShortside:(CGFloat)shortside HighQuality:(BOOL)highQuality;
+ (UIImage*)vImageAspectScaleImage:(CVPixelBufferRef)sourceImage KeepLongside:(CGFloat)longside HighQuality:(BOOL)highQuality;
+ (UIImage*)vImageScaleImage:(CVPixelBufferRef)sourceImage WithSize:(CGSize)destSize HighQuality:(BOOL)highQuality;

+ (CGImageRef)createRotatedImage:(CGImageRef)original degrees:(float)degrees;

@end
