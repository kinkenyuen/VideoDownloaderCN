#pragma mark - 今日头条

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface TTVideoEngineURLInfo : NSObject
@property(copy, nonatomic) NSString *backupURL1;
@end

@interface TTVideoEnginePlayVidSource : NSObject
@property(copy, nonatomic) NSString *usingUrl;
- (id)usingUrlInfo;
@end

@interface TTVideoEngine : NSObject
@property(retain, nonatomic) id playSource; 
@end

@interface TTVPlayer : UIViewController
@property(retain, nonatomic) TTVideoEngine *videoEngine;
@end

@interface TTVPlayerGestureContainerView : UIView <DownloaderManagerDelegeate>
@property(nonatomic) __weak TTVPlayer *player; 
- (void)downloadVideo;
@end

@interface TTVPlayerGestureManager : NSObject
@property(nonatomic) __weak TTVPlayerGestureContainerView *controlView;
@end

%hook TTVPlayerGestureContainerView

%new
- (void)downloadVideo {
    NSURL *url = nil;
    TTVPlayer *player = self.player;
    TTVideoEngine *videoEngine = player.videoEngine;
    id source = videoEngine.playSource;
    if ([source isKindOfClass:%c(TTVideoEnginePlayVidSource)]) {
        TTVideoEnginePlayVidSource *_source = (TTVideoEnginePlayVidSource *)source;
        TTVideoEngineURLInfo *urlInfo = [_source usingUrlInfo];
        url = [NSURL URLWithString:urlInfo.backupURL1];
        if (url && [url isKindOfClass:%c(NSURL)]) {
            DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
            downloadManager.delegate = self;
            [downloadManager downloadVideoWithURL:url];
        }
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

%hook TTVPlayerGestureManager

- (void)longGestureAction:(UILongPressGestureRecognizer *)sender {
    %orig;
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.controlView downloadVideo];
        }];

        UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];

        [alertVC addAction:dAction];
        [alertVC addAction:cAction];

        //search vc
        id vc = [self.controlView nextResponder];
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


