//
//  ViewController.m
//  AudioRecorder
//
//  Created by CDP on 2017/9/14.
//  Copyright © 2017年 CDP. All rights reserved.
//

#import "ViewController.h"

#import "CDPAudioRecorder.h"//引入.h文件


@interface ViewController () <CDPAudioRecorderDelegate> {
    CDPAudioRecorder *_recorder;//recorder对象
    
    UIImageView *_imageView;//音量图片
    UIButton *_recordBt;//录音bt
    UIButton *_playBt;//播放bt
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    
    //详情请看CDPAudioRecorder.h文件
    //初始化录音recorder
    _recorder=[CDPAudioRecorder shareRecorder];
    _recorder.delegate=self;
    
    //创建UI
    [self createUI];
    
}
-(void)dealloc{
    //结束播放
    [_recorder stopPlaying];
    //结束录音
    [_recorder stopRecording];
}

#pragma mark - 创建UI
-(void)createUI{
    UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(10,300,[UIScreen mainScreen].bounds.size.width-20,70)];
    label.font=[UIFont boldSystemFontOfSize:16];
    label.textAlignment=NSTextAlignmentCenter;
    label.numberOfLines=0;
    label.text=@"CDPAudioRecorder可实现录音,播放,转码amr,删除录音等各需求,具体请看.h";
    [self.view addSubview:label];
    
    //音量图片
    _imageView=[[UIImageView alloc] initWithFrame:CGRectMake(80,150,64,64)];
    _imageView.image=[UIImage imageNamed:@"mic_0"];
    [self.view addSubview:_imageView];
    
    //录音bt
    _recordBt=[[UIButton alloc] initWithFrame:CGRectMake(52,230,120,40)];
    [_recordBt setTitle:@"按住 说话" forState:UIControlStateNormal];
    [_recordBt setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    [_recordBt setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_recordBt setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    _recordBt.backgroundColor=[UIColor cyanColor];
    [_recordBt addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchDown];
    [_recordBt addTarget:self action:@selector(endRecord:) forControlEvents:UIControlEventTouchUpInside];
    [_recordBt addTarget:self action:@selector(cancelRecord:) forControlEvents:UIControlEventTouchDragExit];
    _recordBt.layer.cornerRadius = 10;
    [self.view addSubview:_recordBt];
    
    //播放bt
    _playBt=[[UIButton alloc] initWithFrame:CGRectMake(190,230,80,40)];
    _playBt.adjustsImageWhenHighlighted=NO;
    [_playBt setTitle:@"播 放" forState:UIControlStateNormal];
    [_playBt setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _playBt.layer.cornerRadius = 10;
    _playBt.backgroundColor=[UIColor yellowColor];
    [_playBt addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playBt];
}
//alertView提示
-(void)alertWithMessage:(NSString *)message{
    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alertView show];
}
#pragma mark - CDPAudioRecorderDelegate代理事件
//更新音量分贝数峰值(0~1)
-(void)updateVolumeMeters:(CGFloat)value{
    NSInteger no=0;
    
    if (value>0&&value<=0.14) {
        no = 1;
    } else if (value<= 0.28) {
        no = 2;
    } else if (value<= 0.42) {
        no = 3;
    } else if (value<= 0.56) {
        no = 4;
    } else if (value<= 0.7) {
        no = 5;
    } else if (value<= 0.84) {
        no = 6;
    } else{
        no = 7;
    }
    
    NSString *imageName = [NSString stringWithFormat:@"mic_%ld",(long)no];
    _imageView.image = [UIImage imageNamed:imageName];
}
//录音结束(url为录音文件地址,isSuccess是否录音成功)
-(void)recordFinishWithUrl:(NSString *)url isSuccess:(BOOL)isSuccess{
    //url为得到的caf录音文件地址,可直接进行播放,也可进行转码为amr上传服务器
    NSLog(@"录音完成,文件地址:%@",url);
   
    return;
    
    //如果需要将得到的caf录音文件进行转码为amr格式,可按照以下步骤转码
    //生成amr文件将要保存的路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord.amr"];
    
    //caf转码为amr格式
    [CDPAudioRecorder convertCAFtoAMR:[NSURL URLWithString:url].path savePath:filePath];
    
    NSLog(@"转码amr格式成功----文件地址为:%@",filePath);
}
#pragma mark - 各录音点击事件
//按下开始录音
-(void)startRecord:(UIButton *)recordBtn{
    [_recorder startRecording];
}
//点击松开结束录音
-(void)endRecord:(UIButton *)recordBtn{
    double currentTime=_recorder.recorder.currentTime;
    NSLog(@"本次录音时长%lf",currentTime);
    if (currentTime<1) {
        //时间太短
        _imageView.image = [UIImage imageNamed:@"mic_0"];
        [self alertWithMessage:@"说话时间太短"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [_recorder stopRecording];
            [_recorder deleteAudioFile];
        });
    }
    else{
        //成功录音
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [_recorder stopRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                _imageView.image=[UIImage imageNamed:@"mic_0"];
            });
        });
        NSLog(@"已成功录音");
    }
}
//手指从按钮上移除,取消录音
-(void)cancelRecord:(UIButton *)recordBtn{
    _imageView.image = [UIImage imageNamed:@"mic_0"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_recorder stopRecording];
        [_recorder deleteAudioFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertWithMessage:@"已取消录音"];
        });
    });
    
}
#pragma mark - 播放点击事件
//播放录音
-(void)play{
    //播放内部默认地址刚才生成的本地录音文件,不需要转码
    [_recorder playAudioFile];
    
    return;
    
    //如果需要播放amr文件,按照以下步骤转码保存播放
    //获取转换后的amr文件路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord.amr"];
    
    //amr转码为caf可播放格式
    NSString *savefilePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord222.caf"];
    
    //转换格式
    [CDPAudioRecorder convertAMRtoWAV:filePath savePath:savefilePath];
    
    //播放
    [[CDPAudioRecorder shareRecorder] playAudioWithUrl:[NSURL fileURLWithPath:savefilePath].absoluteString];
}


















- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
