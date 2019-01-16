#import <UIKit/UIKit.h>

#pragma mark - 微信

@interface WCStoryPreviewPageView : NSObject
@property(nonatomic,assign) BOOL canDeleteMyOwnStory;

- (void)onShowDownloadAlert;
-(void)onShowActionSheet;
@end

@interface WCStoryActionToolBar
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)addButtonWithTitle:(id)arg1 iconName:(id)arg2 isDestructive:(_Bool)arg3 handler:(id)arg4;
- (void)onShowAlertViewOfDwn;
@end

@interface WCStoryPreivewPageCollectionController : NSObject
@end

@interface WCStoryDataUnit : NSObject
@property(retain, nonatomic) NSMutableArray *storyDataItemArray;
@end

@interface WCStoryDataItem : NSObject
@end

@interface WCStoryMediaItem : NSObject
@property(retain, nonatomic) NSString *videoUrl;
@end

@interface WCStoryMultiContactPreviewCell : NSObject
@end


/**
 下载时刻视频
 */
%hook WCStoryPreviewPageView

- (id)initWithFrame:(struct CGRect)arg1 dataItem:(id)arg2 canDeleteMyOwnStory:(_Bool)arg3 {
    //在别人时刻视频界面添加一个长按手势弹出下载按钮
    id wcStoryPreviewPageView = %orig;
    if (wcStoryPreviewPageView && arg3 == 0) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [wcStoryPreviewPageView addGestureRecognizer:longPressGesture];
    }
    return %orig;
}

%new
/**
 弹出下载选择
 */
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self onShowActionSheet];
    }
}

%new
/**
 移动到系统相册后回调
 */
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"已保存到系统相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    //移除沙盒的缓存文件
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
}

%end

%hook WCStoryActionToolBar
/**
 添加下载按钮及回调
 */
- (id)initWithFrame:(struct CGRect)arg1 {
    id ToolBar = %orig;
    __weak typeof(self) weakSelf = self;
    [ToolBar addButtonWithTitle:@"下载视频" iconName:@"dwn" isDestructive:NO handler:^{
        [weakSelf onShowAlertViewOfDwn];
    }];
    return ToolBar;
}

%new
/**
 下载视频
 */
- (void)onShowAlertViewOfDwn {
    //目标控制器，这里有两种情况，一个是个人页面下拉；另一个是相册->视频动态入口
    id targetVC = [[self nextResponder] nextResponder];
    //可以看作为视频模型
    WCStoryMediaItem *mediaItem = nil;
    //在这里拿到一个WCStoryPreviewPageView对象来做保存到相册后的回调target
    WCStoryPreviewPageView *wcStoryPreviewPageView = nil;
    
    if ([targetVC isKindOfClass:%c(WCStorysPreviewViewController)]) {
        WCStoryPreivewPageCollectionController *m_collectionController = MSHookIvar<WCStoryPreivewPageCollectionController *>(targetVC, "m_collectionController");
        wcStoryPreviewPageView = MSHookIvar<WCStoryPreviewPageView *>(m_collectionController, "m_playingPageView");
        WCStoryDataUnit *_dataUnit = MSHookIvar<WCStoryDataUnit *>(m_collectionController, "_dataUnit");
        NSMutableArray *storyDataItemArray = [_dataUnit storyDataItemArray];
        WCStoryDataItem *dataItem = storyDataItemArray[0];
        if ([dataItem isKindOfClass:%c(WCStoryDataItem)]) {
            mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
        }
    }else if ([targetVC isKindOfClass:%c(WCStoryMultiContactPreviewViewController)]) {
        UICollectionView *m_collectionView = MSHookIvar<UICollectionView *>(targetVC, "m_collectionView");
        UIView *cellView =[m_collectionView subviews][0];
        if ([cellView isKindOfClass:%c(WCStoryMultiContactPreviewCell)]) {
            WCStoryPreivewPageCollectionController *_controller = MSHookIvar<WCStoryPreivewPageCollectionController *>(cellView, "_controller");;
            wcStoryPreviewPageView = MSHookIvar<WCStoryPreviewPageView *>(_controller, "m_playingPageView");
        }
        
        NSMutableArray *_dataUnitArray = MSHookIvar<NSMutableArray *>(targetVC, "_dataUnitArray");
        WCStoryDataUnit *dataUnit = _dataUnitArray[0];
        if ([dataUnit isKindOfClass:%c(WCStoryDataUnit)]) {
            NSMutableArray *_storyDataItemArray = MSHookIvar<NSMutableArray *>(dataUnit, "_storyDataItemArray");
            WCStoryDataItem *dataItem = _storyDataItemArray[0];
            if ([dataItem isKindOfClass:%c(WCStoryDataItem)]) {
                mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
            }
        }
    }
    
    if (mediaItem && [mediaItem isKindOfClass:%c(WCStoryMediaItem)]) {
        //创建下载任务
        NSURLSession *session = [NSURLSession sharedSession];
        NSURL *url = [NSURL URLWithString:[mediaItem videoUrl]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                    [alert show];
                });
            }else {
                //搞个时间戳来命名视频文件
                NSDate *currentDate = [NSDate date];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"YYYYMMddHHmmss";
                NSString *dateString = [formatter stringFromDate:currentDate];
                
                //沙盒路径
                NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:response.suggestedFilename];
                
                //移动下载的文件，否则会在临时目录被覆盖删除
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
                
                //保存到系统相册
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, wcStoryPreviewPageView, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }
        }];
        //3.启动任务
        [downloadTask resume];
    }
}

%end

%hook UIButton
/**
 下载按钮图标
 */
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    if ([[[self titleLabel] text] isEqualToString:@"下载视频"]) {
        NSString *recPath = @"/Library/Application Support/WeChatMomentVideoDwn/";
        NSString *imagePath = [recPath stringByAppendingPathComponent:@"dwn.png"];
        UIImage *icon = [UIImage imageWithContentsOfFile:imagePath];
        %orig((icon ? : image),state);
    }else {
        %orig;
    }
}
%end

/**
 插件开关
 */
static BOOL wechatEnable = YES;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    wechatEnable = [settings objectForKey:@"wechatEnable"] ? [[settings objectForKey:@"wechatEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (wechatEnable)
    {
        %init(_ungrouped);
    }
    
}





