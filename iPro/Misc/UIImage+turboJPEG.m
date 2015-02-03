//
//  UIImage+turboJPEG.m
//  iPro
//
//  Created by zhang fan on 15/1/30.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "UIImage+turboJPEG.h"
#import "turbojpeg.h"

@implementation UIImage (turboJPEG)

- (NSData*)tjEncode:(float)jpegQuality;
{
	TTEasyReleasePool* pool = [TTEasyReleasePool new];
	
	// dump raw buffer
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	[pool autoreleaseWithBlock:^
	{
		CGColorSpaceRelease(colorSpace);
	}];

	int width = CGImageGetWidth(self.CGImage);
	int height = CGImageGetHeight(self.CGImage);
	NSUInteger bytesPerPixel = 4;
	unsigned char *rawData = malloc(height * width * bytesPerPixel);
	[pool autoreleaseWithBlock:^
	{
		free(rawData);
	}];
	
	NSUInteger bytesPerRow = bytesPerPixel * width;
	CGContextRef context = CGBitmapContextCreate(rawData, width, height, 8, bytesPerRow,
												 colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
	[pool autoreleaseWithBlock:^
	{
		CGContextRelease(context);
	}];
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), self.CGImage);
	
	// encode jpeg
	long unsigned int jpegSize = 0;
	unsigned char* compressedImage = NULL;
    tjhandle jpegCompressor = tjInitCompress();
	[pool autoreleaseWithBlock:^
	{
		tjDestroy(jpegCompressor);
		tjFree(compressedImage);
	}];

    tjCompress2(jpegCompressor, rawData, width, 0, height, TJPF_ARGB,
                &compressedImage, &jpegSize, TJSAMP_444, jpegQuality * 100,
                TJFLAG_FASTDCT);
	
	NSData* data = [NSData dataWithBytes:compressedImage length:jpegSize];
	return data;
}

@end
