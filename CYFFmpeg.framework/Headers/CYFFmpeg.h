//
//  CYFFmpeg.h
//  CYFFmpeg
//
//  Created by yellowei on 2019/6/2
//  Copyright © 2019 yellowei. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for XDXFFmpegDynamicLibProject.
FOUNDATION_EXPORT double XDXFFmpegDynamicLibProjectVersionNumber;

//! Project version string for XDXFFmpegDynamicLibProject.
FOUNDATION_EXPORT const unsigned char XDXFFmpegDynamicLibProjectVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <XDXFFmpegDynamicLibProject/PublicHeader.h>

#import <AudioToolbox/AudioToolbox.h>
#import <VideoToolbox/VideoToolbox.h>
#import <Accelerate/Accelerate.h>
#import "libavformat/avformat.h"
#import "libswscale/swscale.h"
#import "libavcodec/avcodec.h"
#import "libavutil/avutil.h"
#import "libswresample/swresample.h"
#import "libavfilter/avfilter.h"
#import "libavdevice/avdevice.h"
#import "libffmpegcmdutils/ffmpeg.h"
#import "libavcodec/avcodec.h"
#import "libavdevice/avdevice.h"
#import "libavfilter/avfilter.h"
#import "libavformat/avformat.h"
#import "libavutil/avutil.h"
#import "libswscale/swscale.h"
#import "libswresample/swresample.h"
#import "libavfilter/buffersrc.h"
#import "libavfilter/buffersink.h"
#import "libavfilter/avfiltergraph.h"
#import "libavutil/eval.h"
#import "libavutil/imgutils.h"
#import "libffmpegcmdutils/ffmpeg.h"
#import "libx264/x264.h"
