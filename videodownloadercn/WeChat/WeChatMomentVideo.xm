#pragma mark - 微信

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

@interface WCStoryPreviewPageView : UIView <DownloaderManagerDelegeate>
@property(nonatomic,assign) BOOL canDeleteMyOwnStory;

- (void)onShowDownloadAlert;
-(void)onShowActionSheet;
- (void)addSubview:(UIView *)view;
- (id)dataItem;
@end

@interface WCStoryActionToolBar
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)addButtonWithTitle:(id)arg1 iconName:(id)arg2 isDestructive:(BOOL)arg3 handler:(id)arg4;
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

- (id)initWithFrame:(struct CGRect)arg1 dataItem:(id)arg2 canDeleteMyOwnStory:(BOOL)arg3 {
    //在别人时刻视频界面添加一个长按手势弹出下载按钮
    id wcStoryPreviewPageView = %orig;
    if (wcStoryPreviewPageView && arg3 == 0) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [wcStoryPreviewPageView addGestureRecognizer:longPressGesture];
    }
    return wcStoryPreviewPageView;
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


static BOOL isShow = NO;
static MBProgressHUD *hud = nil;
%new
- (void)videoDownloadeProgress:(float)progress downloadTask:downloadTask{
    if (!isShow)
    {
        hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Dwonloading...", @"HUD loading title");
        NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
        hud.progressObject = progressObject;
        [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(wechatDownloadTask),
                         downloadTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        isShow = YES;
    }
    hud.progressObject.completedUnitCount = [@(progress * 100)  intValue] ;
    hud.detailsLabel.text = [NSString stringWithFormat:@"%lld%%",hud.progressObject.completedUnitCount];
    if (hud.progressObject.fractionCompleted >= 1.f)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            hud = nil;
            isShow = NO;
        });
    }
}

%new
- (void)cancel {
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(wechatDownloadTask));
    [downloadTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new
- (void)videoDidFinishDownloaded:(NSString * _Nullable)filePath {
    //保存到系统相册
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

%new
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {

    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Save Failed" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.mode = MBProgressHUDModeCustomView;
        NSString *recPath = @"/Library/Application Support/VideoDownloaderCN/";
        NSString *imagePath = [recPath stringByAppendingPathComponent:@"Checkmark.png"];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        hud.customView = [[UIImageView alloc] initWithImage:image];
        hud.square = YES;
        hud.label.text = NSLocalizedString(@"Done", @"HUD done title");
        [hud hideAnimated:YES afterDelay:2.f];
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
    __weak __typeof__(self) weakSelf = self;
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
        //这里查找view逻辑不好，需要优化
        UICollectionView *m_collectionView = MSHookIvar<UICollectionView *>(targetVC, "m_collectionView");
        for (UIView *cellView in [m_collectionView subviews]) {
            if ([cellView isKindOfClass:%c(WCStoryMultiContactPreviewCell)]) {
                for (UIView *view in [cellView subviews]) {
                    for (UIView *collectionView in [view subviews]) {
                        for (UIView *collectionCell in [collectionView subviews]) {
                            for (UIView *v in [collectionCell subviews]) {
                                if (v.subviews.count > 0 && [v.subviews[0] isKindOfClass:%c(WCStoryPreviewPageView)]) {
                                    wcStoryPreviewPageView = v.subviews[0];
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        if (wcStoryPreviewPageView && [wcStoryPreviewPageView isKindOfClass:%c(WCStoryPreviewPageView)]) {
            WCStoryDataItem *dataItem = [wcStoryPreviewPageView dataItem];
            if ([dataItem isKindOfClass:%c(WCStoryDataItem)]) {
                mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
            }
        }
    }

    if (mediaItem && [mediaItem isKindOfClass:%c(WCStoryMediaItem)]) {
        //创建下载任务
        NSURL *url = [NSURL URLWithString:[mediaItem videoUrl]];
        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
        downloadManager.delegate = wcStoryPreviewPageView;
        [downloadManager downloadVideoWithURL:url];
    }
}

%end

%hook UIButton
/**
 下载按钮图标
 */
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    if ([[[self titleLabel] text] isEqualToString:@"下载视频"]) {
        NSString *recPath = @"/Library/Application Support/VideoDownloaderCN/";
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
static BOOL wechatEnable = NO;

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
