//
//  GCDWebServerFileStreamResponse.m
//  KuaiPan
//
//  Created by zhang fan on 14-6-13.
//
//

#import "GCDWebServerFileStreamResponse.h"
#import "GCDWebServerPrivate.h"

#define kFileReadBufferSize (32 * 1024)

@implementation GCDWebServerFileStreamResponse

+ (instancetype)responseWithFileName: (NSString*)fileName
							FileSize: (NSUInteger)fileSize
						  FileStream: (NSInputStream*)fileStream
						IsAttachment: (BOOL)isAttachment
{
	return [[[self class] alloc] initWithFileName:fileName FileSize:fileSize FileStream:fileStream IsAttachment:isAttachment];
}

- (instancetype)initWithFileName: (NSString*)fileName
						FileSize: (NSUInteger)fileSize
					  FileStream: (NSInputStream*)fileStream
					IsAttachment: (BOOL)isAttachment
{
	if ((self = [super init]))
	{
		_fileStream = fileStream;
		
		_fileName = [fileName copy];
		
		if (isAttachment)
		{
			NSData* data = [[_fileName stringByReplacingOccurrencesOfString:@"\"" withString:@""] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
			NSString* lossyFileName = data ? [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] : nil;
			if (lossyFileName)
			{
				NSString* value = [NSString stringWithFormat:@"attachment; filename=\"%@\"; filename*=UTF-8''%@", lossyFileName, GCDWebServerEscapeURLString(_fileName)];
				[self setValue:value forAdditionalHeader:@"Content-Disposition"];
			}
		}
		
		self.contentType = GCDWebServerGetMimeTypeForExtension([_fileName pathExtension]);
		self.contentLength = fileSize;
	}
	
	return self;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark

- (BOOL)open:(NSError**)error
{
	[_fileStream open];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotifyGCDWebServerFileStreamResponseStartSendFile
															object:nil
														  userInfo:@{ @"fileName": _fileName }];
	});
	
	return ![_fileStream streamError];
}

- (NSData*)readData:(NSError**)error
{
	if (!_fileStream.hasBytesAvailable)
		return [NSData data];
	
	NSMutableData* data = [[NSMutableData alloc] initWithLength:kFileReadBufferSize];
	NSInteger readLength = [_fileStream read:data.mutableBytes maxLength:data.length];
	
	if (readLength < 0)
	{
		*error = [_fileStream streamError];
		return nil;
	}
	else
		[data setLength:readLength];
	
	return data;
}

- (void)close
{
	[_fileStream close];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotifyGCDWebServerFileStreamResponseFinishiSendFile
															object:nil
														  userInfo:@{ @"fileName": _fileName }];
	});
}

@end
