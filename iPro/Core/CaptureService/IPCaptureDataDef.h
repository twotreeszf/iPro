//
//  IPCaptureDataDef.h
//  iPro
//
//  Created by zhang fan on 15/1/21.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#ifndef iPro_IPCaptureDataDef_h
#define iPro_IPCaptureDataDef_h

typedef NS_ENUM(NSUInteger, IPCaptrueStatus)
{
	CS_Init = 0,
	CS_Running,
	CS_Recording,
	CS_Lost
};

#define kAPIQueryStatus				@"/queryStatus"
#define kAPIStartCapturing			@"/startCapturing"
#define kAPIStopCapturing			@"/stopCapturing"
#define kAPIStartRecording			@"/startRecording"
#define kAPIStopRecording			@"/stopRecording"
#define kAPISetExpoBias             @"/setExpoBias"

#define kServiceName				@"remoteVideoCapture"
#define kServiceType				@"_remote_video_capture._tcp."
#define kStatus						@"status"
#define kBattery					@"battery"
#define kResult						@"result"
#define kRtspServer                 @"rtspServer"
#define kOK							@"ok"
#define kExpoBias                   @"expoBias"

#endif
