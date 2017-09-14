//
//  CDPAudioRecorder.m
//
//  Created by CDP on 2017/9/12.
//  Copyright © 2017年 CDP. All rights reserved.
//

#import "CDPAudioRecorder.h"

#import "amrFileCodec.h"

#ifdef DEBUG
#    define DLog(fmt,...) NSLog(fmt,##__VA_ARGS__)
#else
#    define DLog(fmt,...) /* */
#endif


@interface CDPAudioRecorder () <AVAudioRecorderDelegate> {
    NSTimer *_timer;//计时器,用于音量监测
    
    AVAudioSession *_session;
    
}

@end

@implementation CDPAudioRecorder


+ (instancetype)shareRecorder{
    static CDPAudioRecorder *recorder=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorder=[[CDPAudioRecorder alloc] init];
    });
    return recorder;
}
-(instancetype)init{
    if (self=[super init]) {
        _session=[AVAudioSession sharedInstance];
        
        [self createRecorder];
    }
    return self;
}
-(void)dealloc{
    if (_timer!=nil) {
        [_timer invalidate];
        _timer=nil;
    }
    
    [_session setActive:NO error:nil];
    _session=nil;
    
    [self stopRecording];
    [self stopPlaying];
}
#pragma mark - 交互
//开始录音
-(void)startRecording {
    if (_recorder==nil) {
        [self createRecorder];
    }
    
    //录音时停止播放
    [self stopPlaying];
    
    //删除曾经生成的录音文件
//    [self deleteAudioFile];
    
    //设置会话类别
    [self setAudioSessionCategory:AVAudioSessionCategoryPlayAndRecord];
    
    //开始录音
    [self.recorder record];
    
    //开启定时器，音量音量分贝数监测
    [self createTimer];
    [_timer setFireDate:[NSDate distantPast]];
}
//结束录音
-(void)stopRecording{
    if (_recorder&&[_recorder isRecording]) {
        [_recorder stop];
    }
    if (_timer) {
        [_timer setFireDate:[NSDate distantFuture]];
    }
}
//删除默认录音地址的录音文件
-(void)deleteAudioFile{
    if (_recordURL) {
        [self deleteFileWithUrl:_recordURL.absoluteString];
    }
}
//删除本地url文件
-(void)deleteFileWithUrl:(NSString *)url{
    if ([url isEqualToString:@""]||url==nil||[url isKindOfClass:[NSNull class]]) {
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:[NSURL URLWithString:url] error:NULL];
}
//开始播放默认录音地址的录音文件(如果正在录音,会自动停止)
-(void)playAudioFile{
    if (_recordURL) {
        [self playAudioWithUrl:_recordURL.absoluteString];
    }
}
//开始播放本地url音频
-(void)playAudioWithUrl:(NSString *)url{
    //播放时停止录音
    [self stopRecording];
    
    //正在播放
    if (_player&&[_player isPlaying]){
        [_player stop];
    }
    
    if ([url isEqualToString:@""]||
        [url isKindOfClass:[NSNull class]]||
        url==nil) {
        DLog(@"CDPAudioRecorder播放音频url为空");
        return;
    }
    //设置会话类别
    [self setAudioSessionCategory:AVAudioSessionCategoryPlayback];

    NSError *playError;
    _player=nil;
    
    _player=[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:url] error:&playError];
    [_player prepareToPlay];
    
    if (_player==nil) {
        DLog(@"CDPAudioRecorder播放音频player为nil--url：%@--error:%@",url,playError);
    }
    else{
        BOOL isPlay=[_player play];
        
        if (isPlay==NO) {
            DLog(@"CDPAudioRecorder播放音频失败url:%@---\n%@",url,playError);
        }
    }
}
//停止播放
-(void)stopPlaying{
    if (_player) {
        [_player stop];
    }
}
//转换为wav格式并生成文件到savePath(showSize是否在控制台打印转换后的文件大小)
+(BOOL)convertAMRtoWAV:(NSString *)fielPath savePath:(NSString *)savePath{
    NSData *data=[NSData dataWithContentsOfFile:fielPath];
    data=DecodeAMRToWAVE(data);
    
    BOOL isSuccess=[data writeToURL:[NSURL fileURLWithPath:savePath] atomically:YES];
    
    if (isSuccess) {
        DLog(@"CDPAudioRecorder转换为wav格式成功,大小为%@",[CDPAudioRecorder fileSizeAtPath:savePath]);
    }
    return isSuccess;
}
//转换为amr格式并生成文件到savePath(showSize是否在控制台打印转换后的文件大小)
+(BOOL)convertCAFtoAMR:(NSString *)fielPath savePath:(NSString *)savePath{
    NSData *data=[NSData dataWithContentsOfFile:fielPath];
    data=EncodeWAVEToAMR(data,1,16);
    
    BOOL isSuccess=[data writeToURL:[NSURL fileURLWithPath:savePath] atomically:YES];

    if (isSuccess) {
        DLog(@"CDPAudioRecorder转换为amr格式成功,大小为%@",[CDPAudioRecorder fileSizeAtPath:savePath]);
    }
    return isSuccess;
}
#pragma mark - 计时器
//音量音量分贝数监测
-(void)volumeMeters:(NSTimer *)timer{
    if (_recorder&&_recorder.isRecording&&[_delegate respondsToSelector:@selector(updateVolumeMeters:)]) {
        //刷新音量音量分贝数
        [_recorder updateMeters];
        
        //获取音量的平均值
        //[recorder averagePowerForChannel:0];
        //音量的最大值
        //[recorder peakPowerForChannel:0];
        
        double value=pow(10,(0.05*[_recorder peakPowerForChannel:0]));
        
        if (value<0) {
            value=0;
        }
        else if (value>1){
            value=1;
        }
        
        [_delegate updateVolumeMeters:value];
    }
}
#pragma mark - AVAudioRecorderDelegate
//录音结束
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (flag) {
        [_session setActive:NO error:nil];
        DLog(@"CDPAudioRecorder录音完成,文件大小为%@",[CDPAudioRecorder fileSizeAtPath:_recordURL.path]);
    }

    if ([_delegate respondsToSelector:@selector(recordFinishWithUrl:isSuccess:)]) {
        [_delegate recordFinishWithUrl:_recordURL.absoluteString isSuccess:flag];
    }
}
#pragma mark - 创建录音
-(void)createRecorder{
    //录音参数设置设置
    NSMutableDictionary *settingDic = [[NSMutableDictionary alloc] init];
    //设置录音格式
    [settingDic setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [settingDic setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [settingDic setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [settingDic setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [settingDic setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    //录音文件最终地址
    _recordURL=[CDPAudioRecorder getAudioRecordFilePath];
    NSError *error=nil;
    
    //初始化AVAudioRecorder
    _recorder = [[AVAudioRecorder alloc] initWithURL:_recordURL settings:settingDic error:&error];
    //开启音量分贝数监测
    _recorder.meteringEnabled = YES;
    _recorder.delegate=self;

    if (_recorder&&[_recorder prepareToRecord]) {
        
    }
    else{
        DLog(@"CDPAudioRecorder录音初始化失败error:%@",error);
    }
}
//创建计时器
-(void)createTimer{
    if (_timer==nil) {
        _timer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(volumeMeters:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}
#pragma mark - 其他方法
//设置AudioSession会话类别
-(void)setAudioSessionCategory:(NSString *)category{
    NSError *sessionError;

    [_session setCategory:category error:&sessionError];
    
    //启动音频会话管理
    if(_session==nil||sessionError){
        DLog(@"CDPAudioRecorder设置AVAudioSession会话类别Category错误:%@",sessionError);
    }else{
        [_session setActive:YES error:nil];
    }
}
//获得录音文件最终地址
+(NSURL *)getAudioRecordFilePath{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord.caf"];
    
    //判断是否存在,不存在则创建
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        NSString *audioRecordDirectories = [filePath stringByDeletingLastPathComponent];
        [fileManager createDirectoryAtPath:audioRecordDirectories withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    return [NSURL fileURLWithPath:filePath];
}
//查看文件大小(iOS是按照1000换算的,而不是1024,可查看NSByteCountFormatterCountStyle)
+(NSString *)fileSizeAtPath:(NSString*)filePath{
    unsigned long long size=0;

    NSFileManager* manager =[NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        size=[[manager attributesOfItemAtPath:filePath error:nil] fileSize];
        
        if (size >=pow(10,9)) {
            // size >= 1GB
            return [NSString stringWithFormat:@"%.2fGB",size/pow(10,9)];
        } else if (size>=pow(10,6)) {
            // 1GB > size >= 1MB
            return [NSString stringWithFormat:@"%.2fMB",size/pow(10,6)];
        } else if (size >=pow(10,3)) {
            // 1MB > size >= 1KB
            return [NSString stringWithFormat:@"%.2fKB",size/pow(10,3)];
        } else {
            // 1KB > size
            return [NSString stringWithFormat:@"%zdB",size];
        }
    }
    return @"0";
}



















@end
