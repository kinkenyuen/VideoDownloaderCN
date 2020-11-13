#pragma mark - Twitter

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface T1SlideshowSlide
@end

@interface TFSTwitterEntityMedia
@end

@interface TFSTwitterEntityMediaVideoInfo
@property(readonly, copy, nonatomic) NSString *primaryUrl;
@end

@interface TFSTwitterEntityMediaVideoVariant : NSObject
@property(readonly, copy, nonatomic) NSString *url; 
@property(readonly, copy, nonatomic) NSString *contentType; 
@end

@interface T1MutableSlideshowSlideViewModel : NSObject
@end

@interface T1SlideshowViewController : UIViewController <DownloaderManagerDelegeate>
@end

%hook T1SlideshowViewController

- (void)viewDidLoad {
    %orig;
    UIView *contentView = MSHookIvar<UIView *>(self, "_contentView");
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [contentView addGestureRecognizer:longPress];
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        T1SlideshowSlide *currentSlide = MSHookIvar<T1SlideshowSlide *>(self, "_currentSlide");
        T1MutableSlideshowSlideViewModel *viewModel = MSHookIvar<T1MutableSlideshowSlideViewModel *>(currentSlide,"_viewModel");    
        TFSTwitterEntityMedia *media = MSHookIvar<TFSTwitterEntityMedia *>(viewModel, "_media");
        TFSTwitterEntityMediaVideoInfo *videoInfo = MSHookIvar<TFSTwitterEntityMediaVideoInfo *>(media,"_videoInfo");
        NSArray *variants = MSHookIvar<NSArray *>(videoInfo,"_variants");
        for (int i = 0;i < variants.count;i++) {
            TFSTwitterEntityMediaVideoVariant *variant = variants[i];
            if ([variant isKindOfClass:%c(TFSTwitterEntityMediaVideoVariant)])
            {
                if ([[variant contentType] isEqualToString:@"video/mp4"]) {
                    //如果是视频
                    //截取标题字符串
                    NSString *url = [variant url];
                    if ([url containsString:@"vid/"]) {
                        NSRange vidRang = [url localizedStandardRangeOfString:@"vid/"];
                        NSString *subString = [url substringFromIndex:(vidRang.location + vidRang.length)];
                        NSRange tmpRang = [subString localizedStandardRangeOfString:@"/"];
                        NSString *title = [subString substringToIndex:tmpRang.location];
                        UIAlertAction *dAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                        downloadManager.delegate = self;
                        [downloadManager downloadVideoWithURL:[NSURL URLWithString:url]];
                        }];
                        [alertVC addAction:dAction];
                    }else {
                        //如果是GIF
                        UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download GIF" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                        downloadManager.delegate = self;
                        [downloadManager downloadVideoWithURL:[NSURL URLWithString:url]];
                        }];
                        [alertVC addAction:dAction];
                    }
                }
            }
        }
        UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {    
        }];
        [alertVC addAction:cAction];
        [self presentViewController:alertVC animated:YES completion:nil];
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
        objc_setAssociatedObject(self, @selector(twitterDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(twitterDownloadTask));
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

- (void)slideshowSeekController:(id)arg1 didLongPressWithRecognizer:(id)arg2 {
    //屏蔽手势冲突
}

%end

/**
 插件开关
 */
static BOOL twitterEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    twitterEnable = [settings objectForKey:@"twitterEnable"] ? [[settings objectForKey:@"twitterEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (twitterEnable)
    {
        %init(_ungrouped);
    }
    
}