//
//  LZJAVPlayer.m
//  PlayerDemo
//
//  Created by LZJ on 2018/3/29.
//  Copyright © 2018年 LZJ. All rights reserved.
//

#import "LZJAVPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface LZJAVPlayer(){
    BOOL _isFirstInit; //是否是第一次初始化，用于回调方法
    CGFloat _bufferTime; //已经缓存的数据, 单位秒
}

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, weak) UIView *parentView; //父视图

@end

@implementation LZJAVPlayer

- (void)start:(NSString *)playURL offset:(NSInteger)offset parentView:(UIView *)parentView {
    if (!parentView || playURL.length == 0) { //一定要有 父视图, 播放URL
        return;
    }
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:playURL]]; //创建item
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem]; //创建player
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = parentView.bounds;
    [parentView.layer addSublayer:self.playerLayer];
    _isFirstInit = true; //第一次启动
    if (offset != 0) {
        [self.playerItem seekToTime:CMTimeMake(offset, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero]; //跳转到指定时间，比较准确
    }
    [self addNotification]; //添加通知监听
    [self playerCallback:LZJCallbackTypeConnectServer];
    
    //KVO添加监听父视图frame,如果父视图frame改变了,也跟着变
    self.parentView = parentView;
}

#pragma mark - Notification & KVO

- (void)dealloc {
}

- (void)addNotification { //添加通知 监听属性变化
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removeNotification { //移除通知 监听
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        if ([keyPath isEqualToString:@"status"]) {
            if ([playerItem status] == AVPlayerItemStatusReadyToPlay) {
                //媒体信息获取完成 首次显示
                if (_isFirstInit) {
                    [self playerCallback:LZJCallbackTypeNotifyMediaInfo];
                    _isFirstInit = false;
                }
                //即将开始播放
                [self playerCallback:LZJCallbackTypePrePlay];
            } else if ([playerItem status] == AVPlayerItemStatusFailed) { //播放出错
                NSError *error = playerItem.error;
                NSDictionary *dict = error.userInfo;
                NSString *desc = [NSString stringWithFormat:@"%@", dict[@"NSUnderlyingError"]];
                if ([desc containsString:@"Code=-12938"]) { //媒体格式错误，找不到播放文件 等原因
                    if ([desc containsString:@"NSOSStatusErrorDomain"]) {
                        [self playerCallback:LZJCallbackTypeNoSourceDemux];
                        return;
                    }
                    [self playerCallback:LZJCallbackTypeNoPlayObject];
                    return;
                }
                if ([desc containsString:@"unsupported URL"]) { //无法处理播放地址
                    [self playerCallback:LZJCallbackTypeNoSourceDemux];
                    return;
                }
                if ([desc containsString:@"The request timed out"]) { //请求超时
                    [self playerCallback:LZJCallbackTypeNetTimeOut];
                    return;
                }
                [self playerCallback:LZJCallbackTypeNetworkError]; //网络错误
                [self.player pause];
            } else if ([playerItem status] == AVPlayerItemStatusUnknown) { //未知错误
                //未知错误
                [self playerCallback:LZJCallbackTypeNetworkError];
                [self.player pause];
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
            NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
            CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
            _bufferTime = timeInterval; //返回 缓存时间大小
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
            //要进入缓存状态
            [self playerCallback:LZJCallbackTypeStartBufferData];
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            //缓冲达到可播放程度了
            //开始播放
            [self playerCallback:LZJCallbackTypeStartPlay];
            //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
            [self.player play];
        }
    }
}

// 播放完成通知
- (void)playbackFinished:(NSNotification *)notification {
    [self playerCallback:LZJCallbackTypePlayFinish];
}

// 代理回调方法
- (void)playerCallback:(LZJCallbackType)type {
    if (self.delegate) {
        [self.delegate playerCallbackWithMsgCode:type player:nil]; //回调各种状态
    }
}

#pragma mark - 实现代理方法

- (CGFloat)getBufferTime {
    return _bufferTime;
}

- (CGFloat)getCurrentTime {
    return CMTimeGetSeconds(self.player.currentItem.currentTime);
}

- (CGFloat)getDuration {
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (void)pause {
    [self.player pause];
}

- (void)resume {
    [self.player play];
}

- (void)seekTo:(NSInteger)value {
    [self.player.currentItem seekToTime:CMTimeMake(value, 1)]; //跳转到指定时间，不是非常准确
}

- (void)setVideoScale:(LZJPlayerScaleModeType)mode {
    // AVLayerVideoGravityResizeAspect 保持纵横比；适合层范围内
    // AVLayerVideoGravityResizeAspectFill 保持纵横比；填充层边界
    // AVLayerVideoGravityResize 拉伸填充层边界
    
    switch (mode) {
        case LZJPlayerScaleModeTypeFit:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case LZJPlayerScaleModeTypeFill:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill ;
            break;
        case LZJPlayerScaleModeTypeResize:
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
        default:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect; //默认合适比例，避免出错
            break;
    }
}

- (void)stop { //停止播放，释放资源
    [self.player pause];
    [self removeNotification];
    [self.playerItem cancelPendingSeeks];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.playerItem = nil;
    self.playerLayer = nil;
    self.player = nil;
}

- (void)printPlayerVer { // AVPlayer不操作
    
}

- (void)setMute:(BOOL)isMute { //设置是否静音
    self.player.muted = isMute;
}

@end
