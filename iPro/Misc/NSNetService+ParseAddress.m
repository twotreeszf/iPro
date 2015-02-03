//
//  NSNetService+ParseAddress.m
//  iPro
//
//  Created by zhang fan on 15/2/3.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "NSNetService+ParseAddress.h"
#import <arpa/inet.h>

@implementation ParseAddressItem

@end

@implementation NSNetService (ParseAddress)

- (NSArray*)parseAddresses
{
    NSMutableArray* addrList = [NSMutableArray new];

    for (NSData* data in self.addresses)
    {
        char addressBuffer[INET6_ADDRSTRLEN] = { 0 };

        typedef union
        {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;

        ip_socket_address* socketAddress = (ip_socket_address*)[data bytes];

        if (socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6))
        {
            const char* addressStr = inet_ntop(
                socketAddress->sa.sa_family,
                (socketAddress->sa.sa_family == AF_INET ? (void*)&(socketAddress->ipv4.sin_addr) : (void*)&(socketAddress->ipv6.sin6_addr)),
                addressBuffer,
                sizeof(addressBuffer));

            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);

            ParseAddressItem* item = [ParseAddressItem new];
            item.address = [NSString stringWithUTF8String:addressStr];
            item.port = port;
            item.isIPV6 = (socketAddress->sa.sa_family == AF_INET6);

            [addrList addObject:item];
        }
    }

    return addrList;
}

- (ParseAddressItem*)firstIPV4Address
{
	NSArray* addrList = [self parseAddresses];
	for (ParseAddressItem* item in addrList)
	{
		if (!item.isIPV6)
			return item;
	}
	
	return nil;
}

@end
