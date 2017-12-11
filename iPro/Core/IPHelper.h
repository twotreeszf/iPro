//
//  IPHelper.h
//  iPro
//
//  Created by fanzhang on 2017/12/11.
//  Copyright © 2017年 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BoolResultBlock)(BOOL success);

@interface IPHelper : NSObject

+ (void)requestPhotoLibraryAuthorization:(BoolResultBlock)resultBlock;
+ (void)requestCameraAuthorization:(BoolResultBlock)resultBlock;
+ (void)requestMicrophoneAuthorization:(BoolResultBlock)resultBlock;

@end
