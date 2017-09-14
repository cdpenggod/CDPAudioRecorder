//
//  CDPAudioRecorder.h
//
//  Created by CDP on 2017/9/12.
//  Copyright © 2017年 CDP. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>


@protocol CDPAudioRecorderDelegate <NSObject>

@optional

/**
 *  更新音量分贝数峰值(0~1)
 */
-(void)updateVolumeMeters:(CGFloat)value;

/**
 *  录音结束(url为录音文件地址,isSuccess是否录音成功)
 */
-(void)recordFinishWithUrl:(NSString *)url isSuccess:(BOOL)isSuccess;



@end




//********************************************************************************************************************
//因为AMR转码需要,请将 TARGETS 里面的 Enable Bitcode 置为NO
//如果不需要转码,并且不想将 Enable Bitcode 置为NO,那么将AMR文件删除,将下面convert转码类方法删掉即可

@interface CDPAudioRecorder : NSObject

/**
 *  单例化方法
 */
+ (instancetype)shareRecorder;


@property (nonatomic,weak) id <CDPAudioRecorderDelegate> delegate;

/** 
 *  录音recorder对象
 */
@property (nonatomic,strong,readonly) AVAudioRecorder *recorder;

/**
 *  录音播放器player对象
 */
@property (nonatomic,strong,readonly) AVAudioPlayer *player;

/**
 *  录制文件地址
 */
@property (nonatomic,strong,readonly) NSURL *recordURL;


/** 
 *  开始录音(如果录音地址之前已有录音文件,会覆盖,且会自动停止当前正在播放的音频)
 */
- (void)startRecording;

/** 
 *  停止录音 
 */
- (void)stopRecording;

/**
 *  删除默认录音地址的录音文件
 */
-(void)deleteAudioFile;

/**
 *  删除本地url文件
 */
-(void)deleteFileWithUrl:(NSString *)url;

/**
 *  开始播放默认录音地址的录音文件(如果正在录音,会自动停止)
 */
-(void)playAudioFile;

/**
 *  开始播放本地url音频(如果正在录音,会自动停止)
 */
-(void)playAudioWithUrl:(NSString *)url;

/**
 *  停止播放音频
 */
-(void)stopPlaying;

/**
 *  转换为amr格式并生成文件到savePath
 */
+(BOOL)convertCAFtoAMR:(NSString *)fielPath savePath:(NSString *)savePath;

/**
 *  转换为wav格式并生成文件到savePath
 */
+(BOOL)convertAMRtoWAV:(NSString *)fielPath savePath:(NSString *)savePath;









@end
