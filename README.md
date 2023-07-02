[![Version](https://img.shields.io/cocoapods/v/CYFFmpeg.svg?style=flat)](http://cocoapods.org/pods/CYFFmpeg)
[![release](https://badgen.net/github/release/yellowei/CYFFmpeg)](https://github.com/yellowei/CYFFmpeg/releases)
[![issues](https://img.shields.io/github/issues/yellowei/CYFFmpeg)](https://github.com/yellowei/CYFFmpeg/issues)
[![forks](https://img.shields.io/github/forks/yellowei/CYFFmpeg)](https://github.com/yellowei/CYFFmpeg/fork)
[![stars](https://img.shields.io/github/stars/yellowei/CYFFmpeg)](https://github.com/yellowei/CYFFmpeg/star)
[![license](https://img.shields.io/github/license/yellowei/CYFFmpeg)](https://github.com/yellowei/CYFFmpeg/blob/master/LICENSE)

# CYFFmpeg


用于ios的ffmpeg动态库

基于ffmpeg3.4版本构建

集成ffmpeg、x264、fdk-acc、ffmpeg-cmdctl、sambclient（samba）、openssl于一体



## 前言

之前的代码仓库直接删了，因为不想使用LFS了

当时为了支持armv7和armv7s架构，有的静态库超过了100MB，必须存放GLFS

要想缩小已使用GLFS仓库的存储使用量，github官方给的建议是直接删库

借此契机，索性引入目前最新的xcode14进行开发，取消对armv7、armv7s的支持，并关闭Bitcode

版本号将从1.0.0开始，不继续沿用0.3.3

后续对ffmpeg的支持也会逐步更新



## 安装方法

通过cocoapods安装ffmpeg动态库到项目

```
pod 'CYFFmpeg'
```



## 基本特性

- [x] CYFFmpeg可以通过CocoaPods进行安装；

- [x] 构建为动态库版本；

- [x] 支持Samba协议，多线程优化；

- [x] 支持Http、Https协议；

- [x] 支持RTMP、HLS、RTSP协议；

- [x] 基于ffmpeg 3.4.2；

- [x] 支持ffmpeg命令行方式调用；

- [x] OpenSSL；

- [x] libX264；

- [x] libSmbClient；

- [x] libFdkAAC

```objective-c
//ffmpeg -i Downloads.mp4 -r 1 -ss 00:20 -vframes 1 %3d.jpg
char* a[] = {
    "ffmpeg",
    "-ss",
    timeInterval,
    "-i",
    movie,
    "-f",
    "image2",
    "-r",
    "25",
    "-vframes",
    "1",
    outPic
};
//加锁
dispatch_semaphore_wait([CYGCDManager sharedManager].av_read_frame_lock, DISPATCH_TIME_FOREVER);
int result = ffmpeg_main(sizeof(a)/sizeof(*a), a);
dispatch_semaphore_signal([CYGCDManager sharedManager].av_read_frame_lock);
```

- [x] 支持x86_64模拟器、armv7/arm64真机运行；

- [ ] Enable Bitcode=YES；

  > Xcode14放弃了从Xcode7引入的该特性

- [x] 开箱即用。



## 示例

* samba库相关函数的使用

```Objective-C
#import <CYFFmpeg/CYFFmpeg.h>

+ (void)testSMB
{
    SMBCCTX * ctx = smbc_new_context();
    if (!ctx) {
        NSLog(@"smbc_new_context failed");
    }
    
    if (!smbc_init_context(ctx))
    {
        NSLog(@"smbc_init_context failed");
    }
    smbc_set_context(ctx);
    
    smbc_setOptionUserData(ctx, @"work");
    smbc_setTimeout(ctx,3000);
    smbc_setFunctionAuthDataWithContext(ctx, my_smbc_get_auth_data_with_context_fn);
    //    smbc_setOptionUserData(ctx, h);
    //    smbc_setFunctionAuthDataWithContext(libsmbc->ctx, libsmbc_get_auth_data);
    
    
    if (smbc_init(NULL, 0) < 0) {
        NSLog(@"smbc_init failed");
    }
    
    //    smbc_get_auth_data_fn fn;
    //    int debug;
    //    smbc_init(fn, debug);
    
    
    //当制定了密码,不会走
    // | O_WRONLY 注意权限问题my_smbc_get_auth_data_with_context_fn
    if ((smbc_open("smb://workgroup;mobile:123123@172.16.9.10/video/test.mp4", O_RDONLY, 0666)) < 0) {
        NSLog(@"File open failed");
    }
    else
    {
        NSLog(@"File open successed");
    }
    //
    //    x264_encoder_encode(NULL, NULL, NULL, NULL, NULL);
    
    //    avcodec_open2(NULL, NULL, NULL);
}

```

* 使用ffmpeg相关函数，直接调用即可

```Objective-C
// 快进到指定时间播放
av_seek_frame(_formatCtx, -1, (seconds)*AV_TIME_BASE + (double)_formatCtx->start_time, AVSEEK_FLAG_BACKWARD);//不指定stream进行seek

// 打开流
NSString *path = @“rtmp://xxxxx”；
AVFormatContext *formatCtx = avformat_alloc_context();
AVDictionary    *_options;
av_dict_set(&_options, "rtsp_transport", "udp", 0);
int ret;
    if (( ret = formatCtx->io_open(formatCtx, &formatCtx->pb, [path UTF8String], AVIO_FLAG_READ | formatCtx->avio_flags, &_options)) < 0){
        return;//打开失败
    }
    // 打开成功之后的逻辑
    // xxxxx

```

* OpenSSL、Fdk-aac的使用请参考网上文章，这里不再一一举例



## 相关阅读


[《iOS中基于ffmpeg开发的播放器打开多个samba链接的解决方案》](https://www.jianshu.com/p/2838b9ddecaf)

[《ffmpeg中samba网络协议的兼容分析(一)》](https://www.jianshu.com/p/ada84499f386)

[《ffmpeg中samba网络协议的兼容分析(一)》](https://www.jianshu.com/p/06b5794a7213)

[《ffmpeg中samba网络协议的兼容分析(一)》](https://www.jianshu.com/p/ada84499f386)
