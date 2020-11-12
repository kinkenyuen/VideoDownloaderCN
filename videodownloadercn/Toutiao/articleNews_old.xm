#pragma mark - 今日头条

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface TTVideoEngine
@property(retain, nonatomic) UIView *playerView;

@end

@interface TTVPlayerControlView <DownloaderManagerDelegeate,UIAlertViewDelegate>
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

@end

@interface TTVDemandPlayer
@end

@interface TTVVideoPlayerView
@end

@interface TSVNewControlOverlayViewController : UIViewController <DownloaderManagerDelegeate>
@end

@interface TSVMusicVideoURLModel : NSObject
@property(nonatomic, readonly) NSArray *urlList;
@end

@interface TSVVideoModel : NSObject
@property(nonatomic, readonly) TSVMusicVideoURLModel *downloadAddr;
@end

@interface TTShortVideoModel : NSObject
@property(nonatomic, readonly) TSVVideoModel *video;
@end

@interface AWEVideoPlayView : UIView
@property(nonatomic, readonly) TTShortVideoModel *model;
@end

%hook TTVideoEngine

- (id)currentHostnameURL {
    id urlString = %orig;
    UIView *playerView = MSHookIvar<UIView *>(self, "_playerView");
    if ([playerView isKindOfClass:%c(TTPlayerView)]) {
        NSURL *url = [NSURL URLWithString:urlString];
        objc_setAssociatedObject(playerView, @selector(ttVideoURL),
                         url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return urlString;
}

%end

%hook TTVPlayerControlView

- (id)initWithFrame:(struct CGRect)arg1 {
    id selfView = %orig;
    if ([selfView isKindOfClass:%c(TTVPlayerControlView)]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [selfView addGestureRecognizer:longPress];
    }
    return selfView;
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        TTVDemandPlayer *delegate = MSHookIvar<TTVDemandPlayer *>(self,"_delegate");
        TTVVideoPlayerView *playerView = MSHookIvar<TTVVideoPlayerView *>(delegate,"_playerView");
        TTPlayerView *playerLayer = MSHookIvar<TTPlayerView *>(playerView,"_playerLayer");
        NSURL *url = objc_getAssociatedObject(playerLayer, @selector(ttVideoURL));
        if (url)
        {
            //寻找当前vc
            id vc = [self nextResponder];
            while (vc) {
                if ([vc isKindOfClass:%c(UIViewController)] || [vc isKindOfClass:%c(UIWindow)])   
                {
                    break;
                }else vc = [vc nextResponder];
            }
            if ([vc isKindOfClass:%c(UIViewController)]) {
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alertVC addAction:cAction];

                UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                    downloadManager.delegate = self;
                    [downloadManager downloadVideoWithURL:url];
                }];
                [alertVC addAction:dAction];

                vc = (UIViewController *)vc;
                [vc presentViewController:alertVC animated:YES completion:nil];
            }else if ([vc isKindOfClass:%c(UIWindow)]) {
                objc_setAssociatedObject(self, @selector(ttVideoURL),
                         url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"VideoDownloaderCN" message:@"Download this Video?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Download", nil];
                [alertV show];
            }
        }
    }
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
        downloadManager.delegate = self;
        [downloadManager downloadVideoWithURL:objc_getAssociatedObject(self, @selector(ttVideoURL))];
    }
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
        objc_setAssociatedObject(self, @selector(ttDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(ttDownloadTask));
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


/*小视频*/
%hook TSVNewControlOverlayViewController

- (void)viewDidLoad {
    %orig;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.view addGestureRecognizer:longPress];
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSURL *url = nil;
        UIView *selfView = self.view;
        NSArray *arrViews = [[selfView superview] subviews];
        for(UIView *view in arrViews) {
            if ([view isKindOfClass:%c(AWEVideoPlayView)]) {
                TTShortVideoModel *model = [(AWEVideoPlayView * )view model];
                TSVVideoModel *videoModel = [model video];
                TSVMusicVideoURLModel *downloadAddr = [videoModel downloadAddr];
                NSArray *urlList = [downloadAddr urlList];
                if (urlList.count > 0) {
                    NSString *urlString = urlList[0];
                    url = [NSURL URLWithString:urlString];
                    break;
                }    
            }
        }
        if (url) {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alertVC addAction:cAction];

            UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
            downloadManager.delegate = self;
            [downloadManager downloadVideoWithURL:url];
        }];
        [alertVC addAction:dAction];
        [self presentViewController:alertVC animated:YES completion:nil];
        }
    }
}

// static BOOL isShow = NO;
// static MBProgressHUD *hud = nil;
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
        objc_setAssociatedObject(self, @selector(ttDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(ttDownloadTask));
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
static BOOL toutiaoEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    toutiaoEnable = [settings objectForKey:@"toutiaoEnable"] ? [[settings objectForKey:@"toutiaoEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (toutiaoEnable)
    {
        %init(_ungrouped);
    }
    
}


