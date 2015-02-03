//
//  NSNetService+ParseAddress.h
//  iPro
//
//  Created by zhang fan on 15/2/3.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParseAddressItem : NSObject

@property (nonatomic, copy)		NSString*	address;
@property (nonatomic, assign)	int			port;
@property (nonatomic, assign)	BOOL		isIPV6;

@end

@interface NSNetService (ParseAddress)

- (NSArray*)parseAddresses;
- (ParseAddressItem*)firstIPV4Address;

@end
