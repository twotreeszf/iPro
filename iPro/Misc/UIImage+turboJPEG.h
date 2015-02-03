//
//  UIImage+turboJPEG.h
//  iPro
//
//  Created by zhang fan on 15/1/30.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (turboJPEG)

- (NSData*)tjEncode:(float)jpegQuality;

@end
