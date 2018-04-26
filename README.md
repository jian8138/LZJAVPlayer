# LZJAVPlayer
系统自带的AVPlayer用起来很费劲，许多方法调用都比较绕。这个是基于AVPlayer封装过后的播放器，提供简单的API，使用起来更方便。
所有功能都在类 LZJAVPlayer 中提供。
常用播放器方法：
/** 播放状态回调代理 */
@property(nonatomic,weak) id<AVPlayerCallbackDelegate> delegate;

/**
 @param playURL 设置播放器的播放URL
 @param offset 偏移时间
 @param parentView 播放视图的宿主视图
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
 */
- (void)setVideoScale:(LZJPlayerScaleModeType)mode;

/**
 设置是否静音
 */
- (void)setMute:(BOOL)isMute;

播放器回调方法：
/**
 播放器播放状态的回调方法
 @param code 回调的各种状态码
 @param player 把播放器本身回调出去
 */
- (void)playerCallbackWithMsgCode:(LZJCallbackType)code player:(LZJAVPlayer *)player;
