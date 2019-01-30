#import <UIKit/UIKit.h>
#import "lib/DownloaderManager/DownloaderManager.h"

@interface QQReadInJoySubsVideoStateView : UIView 
@end

@interface QQReadInJoyVideoView :UIView <DownloaderManagerDelegeate>
@end

@interface QQReadLitePlayer
@end
 
%hook QQReadInJoySubsVideoStateView

- (id)initWithFrame:(struct CGRect)arg1 {
    id selfView = %orig;
    if ([selfView isKindOfClass:%c(QQReadInJoySubsVideoStateView)]) {
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
        QQReadInJoyVideoView *videoView = MSHookIvar<QQReadInJoyVideoView *>(self,"_delegate");
        if (videoView) {
            NSArray *arr = objc_getAssociatedObject(videoView,@selector(videoURLArray));
            if (arr && [arr isKindOfClass:%c(NSArray)] && arr.count > 0){
                NSString *urlString = arr[0];
                if (urlString && [urlString isKindOfClass:%c(NSString)]) {
                url = [NSURL URLWithString:urlString];
                }
            }else {
                url = objc_getAssociatedObject(videoView,@selector(videoURL));
            }
            if (url && [url isKindOfClass:%c(NSURL)]) {
                DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                downloadManager.delegate = videoView;
                [downloadManager setProgressViewWindow:self];
                [downloadManager downloadVideoWithURL:url];   
            }
        }
    }
}

%end

%hook QQReadInJoyVideoView

- (void)playVideoWithURL:(id)arg1 timeOffset:(double)arg2 isLocal:(_Bool)arg3 videoType:(unsigned long long)arg4 {
    objc_setAssociatedObject(self,@selector(videoURLArray),arg1,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
}

- (void)playVideoWithVid:(id)arg1 timeOffset:(double)arg2 {
    objc_setAssociatedObject(self,@selector(videoURLArray),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,@selector(videoURL),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
}

%new 
- (void)videoDidFinishDownloaded {
    objc_setAssociatedObject(self,@selector(videoURLArray),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,@selector(videoURL),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self resignFirstResponder];
}

%end

%hook QQReadLitePlayer

- (void)didMediaUrlRequestFinished:(id)arg1 videoUrls:(id)arg2 viedoDurations:(id)arg3 videoFormatList:(id)arg4 videoDataController:(id)arg5 progInfoDataController:(id)arg6 {
    NSArray *urlArray = arg2;
    NSURL *url = urlArray[0];
    QQReadInJoyVideoView *videoView = MSHookIvar<QQReadInJoyVideoView *>(self,"_delegate");
    if (url && [url isKindOfClass:%c(NSURL)]) {
        NSLog(@"url:%@ - class:%@",url,[url class]);
        NSLog(@"videoView:%@",videoView);
        objc_setAssociatedObject(videoView,@selector(videoURL),url,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    %orig;
}

%end

%hook QQReadInJoySubsViewController

- (void)viewDidAppear:(_Bool)arg1 {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下载提示" message:@"下载视频前请先点击开始播放视频" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    });
}

%end

/*竖屏全屏播放界面*/
%hook RIJShortVideoCell

- (UIView *)praiseMaskView {
    %log;
    return %orig;
}

- (void)setupUI {
    %orig;
    UIView *view = MSHookIvar <UIView *>(self,"_praiseMaskView");
    if ([view isKindOfClass:%c(UIView)]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [view addGestureRecognizer:longPress];
    }
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
        %log;
        NSURL *url = nil; 
        QQReadInJoyVideoView *videoView = MSHookIvar<QQReadInJoyVideoView *>(self,"_videoView");
        if (videoView) {
            NSArray *arr = objc_getAssociatedObject(videoView,@selector(videoURLArray));
            if (arr && [arr isKindOfClass:%c(NSArray)] && arr.count > 0){
                NSString *urlString = arr[0];
                if (urlString && [urlString isKindOfClass:%c(NSString)]) {
                url = [NSURL URLWithString:urlString];
                }
            }else {
                url = objc_getAssociatedObject(videoView,@selector(videoURL));
            }
            if (url && [url isKindOfClass:%c(NSURL)]) {
                DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                downloadManager.delegate = videoView;

                UIView *view = MSHookIvar <UIView *>(self,"_praiseMaskView");
                [downloadManager setProgressViewWindow:view];
                [downloadManager downloadVideoWithURL:url];   
            }
        }
    }
}

%end

/**
 插件开关
 */
static BOOL qqEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    qqEnable = [settings objectForKey:@"qqEnable"] ? [[settings objectForKey:@"qqEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (qqEnable)
    {
        %init(_ungrouped);
    }
    
}



