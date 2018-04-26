//
//  LZJAVPlayer.h
//  PlayerDemo
//
//  Created by LZJ on 2018/3/29.
//  Copyright © 2018年 LZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    LZJCallbackTypeNoSourceDemux = 0, //无法处理播放地址
    LZJCallbackTypeConnectServer = 1, //正在连接服务器
    LZJCallbackTypeNetworkError = 2, //网络错误
    LZJCallbackTypeNoPlayObject = 3, //无播放对象
    LZJCallbackTypeNetTimeOut = 4, //网络超时
    LZJCallbackTypeNotifyMediaInfo = 5, //媒体信息获取完毕
    LZJCallbackTypeStartBufferData = 6, //开始缓冲数据
    LZJCallbackTypePrePlay = 7, //即将开始播放
    LZJCallbackTypeStartPlay = 8, //开始播放
    LZJCallbackTypePlayFinish = 9, //播放完成
} LZJCallbackType; //各种回调状态枚举

typedef enum : NSUInteger {
    LZJPlayerScaleModeTypeFit = 0, //保持纵横比,适合层范围
    LZJPlayerScaleModeTypeFill = 1, //拉伸填充层边界
    LZJPlayerScaleModeTypeResize = 2 //拉伸填充层边界
} LZJPlayerScaleModeType; //视频屏幕拉伸方式

#pragma mark - 回调协议

@class LZJAVPlayer;

@protocol AVPlayerCallbackDelegate <NSObject> //播放器各种状态回调方法

/**
 播放器播放状态的回调方法
 @param code 回调的各种状态码
 @param player 把播放器本身回调出去
 */
- (void)playerCallbackWithMsgCode:(LZJCallbackType)code player:(LZJAVPlayer *)player;

@end

@interface LZJAVPlayer : NSObject //系统AVPlayer播放器

/** 播放状态回调代理 */
@property(nonatomic,weak) id<AVPlayerCallbackDelegate> delegate;

/**
 playURL 设置播放器的播放URL
 bufferTime 缓存时间，AVPlayer不支持该值
 offset 偏移时间
 parentView 播放视图的宿主视图
 子播放器初始化时 用该方法
 */
- (void)start:(NSString *)playURL offset:(NSInteger)offset parentView:(UIView *)parentView;

/** 暂停 */
- (void)pause;

/** 暂停后恢复 */
- (void)resume;

/** 停止播放 无法恢复
 要调用此方法 才能释放资源
 */
- (void)stop;

/**
 进度调整到某个时间点 (不是非常准确)
 value 单位秒
 */
- (void)seekTo:(NSInteger)value;

/** 获取节目的时间长度，单位秒 */
- (CGFloat)getDuration;

/** 获取当前播放的时间，单位秒 */
- (CGFloat)getCurrentTime;

/** 获取已缓冲数据的时间长度，单位秒 */
- (CGFloat)getBufferTime;

/**
 设置视频画面拉伸方式
 @param mode 拉伸方式
 @param redraw AVPlayer(播放录像)不支持该值
 */
- (void)setVideoScale:(LZJPlayerScaleModeType)mode;

/**
 设置是否静音
 */
- (void)setMute:(BOOL)isMute;

@end
