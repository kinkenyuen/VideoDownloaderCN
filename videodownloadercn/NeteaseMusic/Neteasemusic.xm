#pragma mark - 网易云音乐视频 HD

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

@interface NMMVUrlInfo : NSObject
@property(nonatomic, retain) NSString *url;
@end

@interface NMMV : NSObject
@property(nonatomic, retain) NMMVUrlInfo *playUrlInfo;
@end

@interface NMMVPlayView : UIView <DownloaderManagerDelegeate,UIAlertViewDelegate>
@property(retain, nonatomic) UIView *touchView;
@property(retain, nonatomic) NMMV *mv;
- (void)downloadVideo;
@end

%hook NMMVPlayView

- (id)initWithFrame:(struct CGRect)arg1 {
    id ret = %orig;
    UIView *touchView = MSHookIvar<UIView *>(self, "_touchView");
    // NSLog(@"kk | touchView : %@",touchView);
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    [touchView addGestureRecognizer:longPress];
    return ret;
}

%new
- (void)handlePress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"VideoDownloaderCN" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"下载",nil];
        [alert show];
    }
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        [self downloadVideo];
    }
}

%new
- (void)downloadVideo {
    NSURL *url = nil;
    NMMV *mv = [self mv];
    NMMVUrlInfo *urlInfo = [mv playUrlInfo];
    NSString *urlString = [urlInfo url];
    url = [NSURL URLWithString:urlString];
    // NSLog(@"kk | url : %@",url);
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
static BOOL neteasemusicEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    neteasemusicEnable = [settings objectForKey:@"neteasemusicEnable"] ? [[settings objectForKey:@"neteasemusicEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (neteasemusicEnable)
    {
        // NSLog(@"kk | init");
        %init(_ungrouped);
    }
    
}