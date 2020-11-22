#pragma mark - 网易云音乐视频

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow
#define LAST_WINDOW [[UIApplication sharedApplication].windows lastObject]

@interface NMDiscoveryVideoPlayView : UIView <DownloaderManagerDelegeate>
- (void)downloadVideoWithURL:(NSURL *)url;

- (void)downloadVideo;
@end

@interface NMDiscoverVideolistViewController : UIViewController
- (id)currentVideContextInfo;
@end

@interface NMShortVideo : NSObject
@end

@interface NMShortVideoUrlInfo : NSObject
@end

@interface NMVideoPlayView : UIView <DownloaderManagerDelegeate>
- (void)downloadVideoWithURL:(NSURL *)url;

- (void)downloadVideo;
@end

@interface NMVideoPlayController : UIViewController
@end

@interface __NELivePlayerWrapper : NSObject
@end

@interface __NMVideoPlayerWrapper : NSObject
@property(copy, nonatomic) NSURL *contentURL;
@end

@interface NMSquareVideoCell : UIView <DownloaderManagerDelegeate>
@property(retain, nonatomic) UIView *videoContainerView;
- (void)downloadVideo;
@end

static BOOL isShow = NO;
static MBProgressHUD *hud = nil;

#pragma mark - NMDiscoveryVideoPlayView

%hook NMDiscoveryVideoPlayView

- (id)initWithFrame:(struct CGRect)arg1 {
    id selfView = %orig;
    if ([selfView isKindOfClass:%c(NMDiscoveryVideoPlayView)]) {
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
    //视频tab界面
    id targetCell = [[self nextResponder] nextResponder];
    if ([targetCell isKindOfClass:%c(NMDiscoveryVideoCell)]) {
        NMShortVideo *discoveryVideo = MSHookIvar<NMShortVideo *>(targetCell, "_discoveryVideo");
        if ([discoveryVideo isKindOfClass:%c(NMShortVideo)]) {
            NMShortVideoUrlInfo *urlInfo = MSHookIvar<NMShortVideoUrlInfo *>(discoveryVideo, "_urlInfo");
            if ([urlInfo isKindOfClass:%c(NMShortVideoUrlInfo)]) {
                NSString *urlStr = MSHookIvar<NSString *>(urlInfo, "_urlStr");
                if (urlStr) {
                    url = [NSURL URLWithString:urlStr];
                }
            }
        }
        if (url)
        {
            DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
            downloadManager.delegate = self;
            [downloadManager downloadVideoWithURL:url];
        }
    }
}

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
        objc_setAssociatedObject(self, @selector(neteaseMusicDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(neteaseMusicDownloadTask));
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

#pragma mark - NMVideoPlayView

%hook NMVideoPlayView

- (id)initWithFrame:(struct CGRect)arg1 contextType:(unsigned long long)arg2 {
    id selfView = %orig;
    if ([selfView isKindOfClass:%c(NMVideoPlayView)]) {
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
    /**
     情况1
     */
    NMShortVideo *video = MSHookIvar<NMShortVideo *>(self, "_resource");
    if ([video isKindOfClass:%c(NMShortVideo)]) {
        NMShortVideoUrlInfo *urlInfo = MSHookIvar<NMShortVideoUrlInfo *>(video, "_urlInfo");
        if ( urlInfo && [urlInfo isKindOfClass:%c(NMShortVideoUrlInfo)]) {
            NSString *urlStr = MSHookIvar<NSString *>(urlInfo, "_urlStr");
            if (urlStr) {
                url = [NSURL URLWithString:urlStr];
            }
        }
    }
        
    /**
     情况2，
     */
    NMVideoPlayController *targetVC = MSHookIvar<NMVideoPlayController *>(self, "_playViewDelegate");
    if ([targetVC isKindOfClass:%c(NMVideoPlayController)]) {
        url = MSHookIvar<NSURL *>(targetVC, "_contentUrl");
    }
        
    /**
     情况3 关注人页面打开的视频
     */
    // __NELivePlayerWrapper *nelPlayer = MSHookIvar<__NELivePlayerWrapper *>(targetVC, "_player");
    // if ([nelPlayer isKindOfClass:%c(__NELivePlayerWrapper)]) {
    //     NSURL *contentURL = MSHookIvar<NSURL *>(nelPlayer, "_contentURL");
    //     if (contentURL) {
    //         url = contentURL;
    //     }
    // }

    if (url)
    {
        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
        downloadManager.delegate = self;
        [downloadManager downloadVideoWithURL:url];
    }
}

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
        objc_setAssociatedObject(self, @selector(neteaseMusicDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(neteaseMusicDownloadTask));
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


%hook NMSquareVideoCell

- (id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    id ret = %orig;
    UIView *videoContainerView = [(NMSquareVideoCell*)ret videoContainerView];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [videoContainerView addGestureRecognizer:longPress];
    return ret;
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
    // NMVideoMLog *videoLog = [self videoLog];
    // NMShortVideoInfo *video = [videoLog video];
    NSURL *videoURL = nil;
    id player = MSHookIvar<id>(self, "_player");
    if ([player isKindOfClass:%c(__NMVideoPlayerWrapper)]) {
        videoURL = [player contentURL];
    }
    if (videoURL) {
        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
        downloadManager.delegate = self;
        [downloadManager downloadVideoWithURL:videoURL];
    }
}

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
        objc_setAssociatedObject(self, @selector(neteaseMusicDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(neteaseMusicDownloadTask));
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

/**
 插件开关
 */
static BOOL neteasemusicEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    neteasemusicEnable = [settings objectForKey:@"neteasemusicEnable"] ? [[settings objectForKey:@"neteasemusicEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (neteasemusicEnable)
    {
        %init(_ungrouped);
    }
    
}