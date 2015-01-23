//
//  GCDWebServerFileStreamResponse.h
//  KuaiPan
//
//  Created by zhang fan on 14-6-13.
//
//

#import "GCDWebServerResponse.h"

#define kNotifyGCDWebServerFileStreamResponseStartSendFile			@"GCDWebServer.Response.FileStream.StartSendFile"
#define kNotifyGCDWebServerFileStreamResponseFinishiSendFile		@"GCDWebServer.Response.FileStream.FinishiSendFile"

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark

@interface GCDWebServerFileStreamResponse : GCDWebServerResponse
{
	@private
	NSInputStream*	_fileStream;
	NSString*		_fileName;
}

+ (instancetype)responseWithFileName: (NSString*)fileName
							FileSize: (NSUInteger)fileSize
						  FileStream: (NSInputStream*)fileStream
						IsAttachment: (BOOL)isAttachment;

- (instancetype)initWithFileName: (NSString*)fileName
						FileSize: (NSUInteger)fileSize
					  FileStream: (NSInputStream*)fileStream
					IsAttachment: (BOOL)isAttachment;

@end
