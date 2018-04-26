//
//  ViewController.m
//  PlayerDemo
//
//  Created by LZJ on 2018/3/28.
//  Copyright © 2018年 LZJ. All rights reserved.
//

#import "ViewController.h"
#import "LZJAVPlayer.h"

@interface ViewController ()<AVPlayerCallbackDelegate>

@property (weak, nonatomic) IBOutlet UISlider *progressSlider; //进度条

@property (weak, nonatomic) IBOutlet UILabel *currentTimeLb; //当前时间

@property (weak, nonatomic) IBOutlet UILabel *totalTimeLb; //总时间

@property (weak, nonatomic) IBOutlet UILabel *statusLb; //状态

@property (weak, nonatomic) IBOutlet UIButton *pauseBtn; //暂停/播放

@property (weak, nonatomic) IBOutlet UISlider *cacheSlider;

@property (nonatomic, strong) LZJAVPlayer *myPlayer; //播放器

@property (nonatomic, strong) NSTimer *timer; //定时器

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myPlayer = [[LZJAVPlayer alloc] init];
    self.myPlayer.delegate = self;
    
    UIView *parentView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 300)];
    parentView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:parentView];
    
    NSString *playURL = @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"; //URL
    
    [self.myPlayer start:playURL offset:0 parentView:parentView]; //开始播放

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(timerAction) userInfo:nil repeats:true];
}

- (void)timerAction {
    float duration = [self.myPlayer getDuration];
    float currentTime = [self.myPlayer getCurrentTime];
    float bufferTime = [self.myPlayer getBufferTime];
    self.currentTimeLb.text = [NSString stringWithFormat:@"%.2f", currentTime];
    self.progressSlider.value = currentTime / duration;
    self.cacheSlider.value = bufferTime / duration;
}

- (void)playerCallbackWithMsgCode:(LZJCallbackType)code player:(LZJAVPlayer *)player {
    switch (code) {
        case LZJCallbackTypeNoSourceDemux:
            NSLog(@"无法处理播放地址");
            self.statusLb.text = @"无法处理播放地址";
            break;
        case LZJCallbackTypeConnectServer:
            NSLog(@"正在连接服务器");
            self.statusLb.text = @"正在连接服务器";
            break;
        case LZJCallbackTypeNetworkError:
            NSLog(@"网络错误");
            self.statusLb.text = @"网络错误";
            break;
        case LZJCallbackTypeNoPlayObject:
            NSLog(@"无播放对象");
            self.statusLb.text = @"无播放对象";
            break;
        case LZJCallbackTypeNetTimeOut:
            NSLog(@"网络超时");
            self.statusLb.text = @"网络超时";
            break;
        case LZJCallbackTypeNotifyMediaInfo:
            NSLog(@"媒体信息获取完毕");
            self.statusLb.text = @"媒体信息获取完毕";
            self.totalTimeLb.text = [NSString stringWithFormat:@"%.2f", [self.myPlayer getDuration]];
            break;
        case LZJCallbackTypeStartBufferData:
            NSLog(@"开始缓冲数据");
            self.statusLb.text = @"开始缓冲数据";
            break;
        case LZJCallbackTypePrePlay:
            NSLog(@"即将开始播放");
            self.statusLb.text = @"即将开始播放";
            break;
        case LZJCallbackTypeStartPlay:
            NSLog(@"开始播放");
            self.statusLb.text = @"播放中";
            break;
        case LZJCallbackTypePlayFinish:
            NSLog(@"播放完成");
            self.statusLb.text = @"播放完成";
            break;
        default:
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!self.pauseBtn.selected) {
        [self pauseBtnAction:self.pauseBtn];
    }
}

- (IBAction)pauseBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.myPlayer pause];
        [sender setTitle:@"播放" forState:UIControlStateNormal];
    } else {
        [self.myPlayer resume];
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (IBAction)progressChange:(UISlider *)sender {
    float duration = [self.myPlayer getDuration];
    [self.myPlayer seekTo:duration *sender.value];
}

- (IBAction)screenScaleAction:(UIButton *)sender {
    static int i = 0;
    i++;
    int scale = i % 3;
    [self.myPlayer setVideoScale:scale];
}

- (IBAction)cancelAction:(UIButton *)sender { //取消
    NSLog(@"结束播放");
    [self.myPlayer stop];
    [self.timer invalidate];
    self.timer = nil;
}

- (IBAction)muteActionBtn:(UIButton *)sender { //静音
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.myPlayer setMute:true];
        [sender setTitle:@"开声音" forState:UIControlStateNormal];
    } else {
        [self.myPlayer setMute:false];
        [sender setTitle:@"静音" forState:UIControlStateNormal];
    }
}

@end
