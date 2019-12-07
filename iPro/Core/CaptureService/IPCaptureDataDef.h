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

#define kAPIQueryStatus				@"/querystatus"
#define kAPIStartCapturing			@"/startCapturing"
#define kAPIStopCapturing			@"/stopCapturing"
#define kAPIStartRecording			@"/startrecording"
#define kAPIStopRecording			@"/stoprecording"

#define kServiceName				@"RemoteVideoCapture"
#define kServiceType				@"_remote_video_capture._tcp."
#define kStatus						@"Status"
#define kBattery					@"Battery"
#define kResult						@"Result"
#define kRtspServer                 @"RtspServer"
#define kOK							@"OK"

#endif
