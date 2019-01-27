#pragma mark - 百度贴吧

#import <UIKit/UIKit.h>
#import "lib/DownloaderManager/DownloaderManager.h"

@interface TBCVideoPlayerDisplayView <UIAlertViewDelegate>
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;
@end

@interface TBCVVideoPlaybackTableViewCell

@end

@interface TBCVVideoDetailItem
@property(copy, nonatomic) NSString *videoUrl;
@end

@interface TBCVideoMiddleItem
@end

@interface TBCVideoMiddleMediaItem
@end

%hook TBCVideoPlayerDisplayView

- (id)init {
    id selfView = %orig;
    if ([selfView isKindOfClass:%c(TBCVideoPlayerDisplayView)]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [selfView addGestureRecognizer:longPress];
    }
    return selfView;
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"下载该视频?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        [alert show];
    }
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSURL *url = nil;
        id targetCell = [[self nextResponder] nextResponder];
        if ([targetCell isKindOfClass:%c(TBCVVideoPlaybackTableViewCell)]) {
            TBCVVideoDetailItem *videoInfo = MSHookIvar<TBCVVideoDetailItem *>(targetCell, "_videoInfo");
            NSString *videoUrl = [videoInfo videoUrl];
            if (videoUrl) {
            url = [NSURL URLWithString:videoUrl];
            }
        }else if ([targetCell isKindOfClass:%c(TBCVideoMiddleTableViewCell)]) {
            TBCVideoMiddleItem *videoItem = MSHookIvar<TBCVideoMiddleItem *>(targetCell,"_videoItem");
            TBCVideoMiddleMediaItem *video = MSHookIvar<TBCVideoMiddleMediaItem *>(videoItem,"_video");
            NSString *videoUrl = MSHookIvar<NSString *>(video,"_videoUrl");
            if (videoUrl) {
            url = [NSURL URLWithString:videoUrl];
            }
        }
        if (url) {
            DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
            [downloadManager setProgressViewWindow:[UIApplication sharedApplication].keyWindow];
            [downloadManager downloadVideoWithURL:url];
        }
    }
}

%end

/**
 插件开关
 */
static BOOL baiduTBEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    baiduTBEnable = [settings objectForKey:@"baiduTBEnable"] ? [[settings objectForKey:@"baiduTBEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (baiduTBEnable)
    {
        %init(_ungrouped);
    }
    
}