/*
旧版代码
*/
#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface QQReadInJoySubsVideoStateView : UIView 
- (void)downloadVideo;
@end

@interface QQReadInJoyVideoView :UIView <DownloaderManagerDelegeate>
@end

@interface QQReadLitePlayer
@end

@interface RIJShortVideoCell 
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)downloadVideo;
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
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
        UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self downloadVideo];
        }];

        UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertVC addAction:dAction];
        [alertVC addAction:cAction];

        //寻找当前vc
        id vc = [self nextResponder];
        while (vc) {
            if ([vc isKindOfClass:%c(UIViewController)])   
            {
                break;
            }else vc = [vc nextResponder];
        }
        if ([vc isKindOfClass:%c(UIViewController)]) {
            vc = (UIViewController *)vc;
            [vc presentViewController:alertVC animated:YES completion:nil];
        }
    }
}

%new
- (void)downloadVideo {
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
            [downloadManager downloadVideoWithURL:url];   
        }
    }
}

%end


%hook QQReadInJoyVideoView

- (void) playVideoWithURL:(id)arg1 timeOffset:(double)arg2 isLocal:(BOOL)arg3 {
    objc_setAssociatedObject(self,@selector(videoURLArray),arg1,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
}

- (void)playVideoWithVid:(id)arg1 timeOffset:(double)arg2 {
    objc_setAssociatedObject(self,@selector(videoURLArray),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,@selector(videoURL),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
}

static BOOL isShow = NO;
static MBProgressHUD *hud = nil;
%new
- (void)videoDownloadeProgress:(float)progress downloadTask:(NSURLSessionDownloadTask * _Nullable)downloadTask {
    if (!isShow)
    {
        hud = [MBProgressHUD showHUDAddedTo:KEY_WINDOW animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Downloading...", @"HUD loading title");
        NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
        hud.progressObject = progressObject;
        [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(qqDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(qqDownloadTask));
    [downloadTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new 
- (void)videoDidFinishDownloaded:(NSString *)filePath {
    objc_setAssociatedObject(self,@selector(videoURLArray),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self,@selector(videoURL),nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    //保存到系统相册
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

%new
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Save Failed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:KEY_WINDOW animated:YES];
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

%hook QQReadLitePlayer

- (void)didMediaUrlRequestFinished:(id)arg1 videoUrls:(id)arg2 viedoDurations:(id)arg3 videoFormatList:(id)arg4 videoDataController:(id)arg5 progInfoDataController:(id)arg6 {
    NSArray *urlArray = arg2;
    NSURL *url = urlArray[0];
    QQReadInJoyVideoView *videoView = MSHookIvar<QQReadInJoyVideoView *>(self,"_delegate");
    if (url && [url isKindOfClass:%c(NSURL)]) {
        objc_setAssociatedObject(videoView,@selector(videoURL),url,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    %orig;
}

%end

%hook QQReadInJoySubsViewController

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下载提示" message:@"下载视频前请先让视频开始播放" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    });
}

%end

/*竖屏全屏播放界面*/
%hook RIJShortVideoCell

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
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
        UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self downloadVideo];
        }];

        UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertVC addAction:dAction];
        [alertVC addAction:cAction];

        //寻找当前vc
        id vc = [self nextResponder];
        while (vc) {
            if ([vc isKindOfClass:%c(UIViewController)])   
            {
                break;
            }else vc = [vc nextResponder];
        }
        if ([vc isKindOfClass:%c(UIViewController)]) {
            vc = (UIViewController *)vc;
            [vc presentViewController:alertVC animated:YES completion:nil];
        }
    }
}

%new
- (void)downloadVideo {
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
            [downloadManager downloadVideoWithURL:url];   
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




