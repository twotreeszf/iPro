//
//  TTImageUtilities.m
//  iPro
//
//  Created by zhang fan on 15/1/22.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "TTImageUtilities.h"
#import <Accelerate/Accelerate.h>
#import "UIImage+Resize.h"

@implementation TTImageUtilities

+ (UIImage*)imageFromPixelBuffer:(CVPixelBufferRef)sourceImage
{
	TTEasyReleasePool* pool = [TTEasyReleasePool new];
	
	/*Lock the image buffer*/
	CVPixelBufferLockBaseAddress(sourceImage,0);
	[pool autoreleaseWithBlock:^
	{
		CVPixelBufferUnlockBaseAddress(sourceImage, 0);
	}];
	
	/*Get information about the image*/
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(sourceImage);
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(sourceImage);
	size_t width = CVPixelBufferGetWidth(sourceImage);
	size_t height = CVPixelBufferGetHeight(sourceImage);
	
	/*Create a CGImageRef from the CVImageBufferRef*/
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	[pool autoreleaseWithBlock:^
	{
		CGColorSpaceRelease(colorSpace);
	}];
	
	CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height,
													8, bytesPerRow, colorSpace,
													kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	[pool autoreleaseWithBlock:^
	{
		CGContextRelease(newContext);
	}];
	
	CGImageRef newImage = CGBitmapContextCreateImage(newContext);
	[pool autoreleaseWithBlock:^
	{
		CGImageRelease(newImage);
	}];
	
	UIImage *image= [UIImage imageWithCGImage:newImage];
	return image;
}

+ (UIImage*)aspectScaleImage:(CVPixelBufferRef)sourceImage KeepShortside:(CGFloat)shortside
{
	CGFloat width = CVPixelBufferGetWidth(sourceImage);
	CGFloat height = CVPixelBufferGetHeight(sourceImage);
	
	CGFloat destWidth;
	CGFloat destHeight;
	if (width > height)
	{
		destHeight = shortside;
		destWidth = (width / height) * destHeight;
	}
	else
	{
		destWidth = shortside;
		destHeight = (height / width) * destWidth;
	}
	
	return [self scaleImage:sourceImage WithSize:CGSizeMake(destWidth, destHeight)];
}

+ (UIImage*)aspectScaleImage:(CVPixelBufferRef)sourceImage KeepLongside:(CGFloat)longside
{
	CGFloat width = CVPixelBufferGetWidth(sourceImage);
	CGFloat height = CVPixelBufferGetHeight(sourceImage);
	
	CGFloat destWidth;
	CGFloat destHeight;
	if (width < height)
	{
		destHeight = longside;
		destWidth = (width / height) * destHeight;
	}
	else
	{
		destWidth = longside;
		destHeight = (height / width) * destWidth;
	}

	return [self scaleImage:sourceImage WithSize:CGSizeMake(destWidth, destHeight)];
}

+ (UIImage*)scaleImage:(CVPixelBufferRef)sourceImage WithSize:(CGSize)destSize
{
	UIImage* image = [self imageFromPixelBuffer:sourceImage];
	return [image resizedImageToSize:destSize];
}

+ (UIImage*)vImageAspectScaleImage:(CVPixelBufferRef)sourceImage KeepShortside:(CGFloat)shortside HighQuality:(BOOL)highQuality
{
    CGFloat width = CVPixelBufferGetWidth(sourceImage);
    CGFloat height = CVPixelBufferGetHeight(sourceImage);

    CGFloat destWidth;
    CGFloat destHeight;
    if (width > height)
    {
        destHeight = shortside;
        destWidth = (width / height) * destHeight;
    }
    else
    {
        destWidth = shortside;
        destHeight = (height / width) * destWidth;
    }

    return [self vImageScaleImage:sourceImage WithSize:CGSizeMake(destWidth, destHeight) HighQuality:highQuality];
}

+ (UIImage*)vImageAspectScaleImage:(CVPixelBufferRef)sourceImage KeepLongside:(CGFloat)longside HighQuality:(BOOL)highQuality
{
    CGFloat width = CVPixelBufferGetWidth(sourceImage);
    CGFloat height = CVPixelBufferGetHeight(sourceImage);

    CGFloat destWidth;
    CGFloat destHeight;
    if (width < height)
    {
        destHeight = longside;
        destWidth = (width / height) * destHeight;
    }
    else
    {
        destWidth = longside;
        destHeight = (height / width) * destWidth;
    }

    return [self vImageScaleImage:sourceImage WithSize:CGSizeMake(destWidth, destHeight) HighQuality:highQuality];
}

+ (UIImage*)vImageScaleImage:(CVPixelBufferRef)sourceImage WithSize:(CGSize)destSize HighQuality:(BOOL)highQuality
{
    UIImage* destImage = nil;
    {
		TTEasyReleasePool* pool = [TTEasyReleasePool new];

        // First, convert the UIImage to an array of bytes, in the format expected by vImage.
        NSUInteger sourceWidth = CVPixelBufferGetWidth(sourceImage);
        NSUInteger sourceHeight = CVPixelBufferGetHeight(sourceImage);
        NSUInteger sourceBytesPerRow = CVPixelBufferGetBytesPerRow(sourceImage);
        NSUInteger bytesPerPixel = sourceBytesPerRow / sourceWidth;

        // We now have the source data.  Construct a pixel array
        NSUInteger destWidth = (NSUInteger)destSize.width;
        NSUInteger destHeight = (NSUInteger)destSize.height;
        NSUInteger destBytesPerRow = bytesPerPixel * destWidth;
        unsigned char* destData = (unsigned char*)calloc(destHeight * destWidth * 4, sizeof(unsigned char));
        ERROR_CHECK_BOOL(destData);
		[pool autoreleaseCOBJ:destData];

        // Now create vImage structures for the two pixel arrays.
		CVPixelBufferLockBaseAddress(sourceImage, 0);
		unsigned char* sourceData = CVPixelBufferGetBaseAddress(sourceImage);
		[pool autoreleaseWithBlock:^
		{
			CVPixelBufferUnlockBaseAddress(sourceImage, 0);
		}];

        vImage_Buffer src = {
            .data = sourceData,
            .height = sourceHeight,
            .width = sourceWidth,
            .rowBytes = sourceBytesPerRow
        };

        vImage_Buffer dest = {
            .data = destData,
            .height = destHeight,
            .width = destWidth,
            .rowBytes = destBytesPerRow
        };

        // Carry out the scaling.
        vImage_Error err = vImageScale_ARGB8888(
            &src,
            &dest,
            NULL,
            highQuality ? kvImageHighQualityResampling : kvImageNoFlags);
        ERROR_CHECK_BOOL(kvImageNoError == err);

        // Convert the destination bytes to a UIImage.
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		[pool autoreleaseWithBlock:^
		{
			CGColorSpaceRelease(colorSpace);
		}];
		
        NSUInteger bitsPerComponent = 8;
        CGContextRef destContext = CGBitmapContextCreate(destData,
                                                         destWidth,
                                                         destHeight,
                                                         bitsPerComponent,
                                                         destBytesPerRow,
                                                         colorSpace,
                                                         kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
		[pool autoreleaseWithBlock:^
		{
			CGContextRelease(destContext);
		}];
		
        CGImageRef destRef = CGBitmapContextCreateImage(destContext);
		[pool autoreleaseWithBlock:^
		{
			CGImageRelease(destRef);
		}];

        // Store the result.
        destImage = [UIImage imageWithCGImage:destRef];
    }

Exit0:
    return destImage;
}

+ (CGImageRef)createRotatedImage:(CGImageRef)original degrees:(float)degrees CF_RETURNS_RETAINED
{
    if (degrees == 0.0f) {
        CGImageRetain(original);
        return original;
    } else {
        double radians = degrees * M_PI / 180;
        
#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
        radians = -1 * radians;
#endif
        
        size_t _width = CGImageGetWidth(original);
        size_t _height = CGImageGetHeight(original);
        
        CGRect imgRect = CGRectMake(0, 0, _width, _height);
        CGAffineTransform __transform = CGAffineTransformMakeRotation(radians);
        CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, __transform);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     rotatedRect.size.width,
                                                     rotatedRect.size.height,
                                                     CGImageGetBitsPerComponent(original),
                                                     0,
                                                     colorSpace,
                                                     kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
        CGContextSetAllowsAntialiasing(context, FALSE);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGColorSpaceRelease(colorSpace);
        
        CGContextTranslateCTM(context,
                              +(rotatedRect.size.width/2),
                              +(rotatedRect.size.height/2));
        CGContextRotateCTM(context, radians);
        
        CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                               -imgRect.size.height/2,
                                               imgRect.size.width,
                                               imgRect.size.height),
                           original);
        
        CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        
        return rotatedImage;
    }
}

@end
