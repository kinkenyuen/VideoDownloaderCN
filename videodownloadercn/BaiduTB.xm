#pragma mark - 百度贴吧

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

@interface TBCVideoPlayerDisplayView : UIView <DownloaderManagerDelegeate>
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)downloadVideo;
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
        downloadManager.delegate = self;
        [downloadManager downloadVideoWithURL:url];
    }
}

static BOOL isShow = NO;
static MBProgressHUD *hud = nil;
%new
- (void)videoDownloadeProgress:(float)progress downloadTask:(NSURLSessionDownloadTask * _Nullable)downloadTask {
    if (!isShow)
    {
        hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Downloading...", @"HUD loading title");
        NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
        hud.progressObject = progressObject;
        [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(baiduTBDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(baiduTBDownloadTask));
    [downloadTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new
- (void)videoDidFinishDownloaded:(NSString * _Nonnull)filePath {
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