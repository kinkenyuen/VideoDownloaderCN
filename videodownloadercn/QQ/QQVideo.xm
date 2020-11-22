#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface QQReadLitePlayer
@end

@interface SPVideoView : UIView
- (void)downloadVideo;
@end

@interface SPMediaInfo : NSObject
@property(copy, nonatomic) NSString *url;
@end

@interface SPPlayerWrapper : NSObject
@property(retain, nonatomic) SPMediaInfo *mediaInfo;
@end

@interface VAViewController : UIViewController <DownloaderManagerDelegeate>
@property(readonly, nonatomic) __weak UIScrollView *mainScrollView;
- (void)downloadVideo;
@end

@interface VACollectionView : UICollectionView
@end

@interface VACollectionViewCell : UICollectionViewCell
@end

//PTSPageController

%hook QQReadInJoySubsViewController

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下载提示" message:@"视频播放界面摇一摇弹出下载窗口" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    });
}

%end


%hook VAViewController

- (void)viewDidLoad  
{  
    %orig;
    [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:YES];  
    [self becomeFirstResponder]; 
}  

- (void)viewWillDisappear:(BOOL)animated  
{  
    %orig;
    [self resignFirstResponder];  
}

- (void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    //检测到摇动开始
    if (motion == UIEventSubtypeMotionShake)
    {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"VideoDownloaderCN" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction *dAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self downloadVideo];
        }];

        UIAlertAction *cAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }];

        [alertVC addAction:dAction];
        [alertVC addAction:cAction];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

%new
- (void)downloadVideo {
    //查找视频view，分析了很久只能按视图层次遍历，做法不太合理
    if ([self.mainScrollView isKindOfClass:%c(VACollectionView)]) {
        VACollectionView *cV = (VACollectionView *)self.mainScrollView;
        VACollectionViewCell *cell = cV.visibleCells.firstObject;
        UIView *_contentView = [cell contentView];
        UIView *targetView = _contentView.subviews[0];//UIView
        if (targetView.subviews.count) {
            targetView = targetView.subviews[0];//VADivView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[1];//VADivView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[2];//VADivView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[0];//VADivView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[0];//VADivView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[0];//VADivView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[0];//VAWrapView
        }
        if (targetView.subviews.count) {
            targetView = targetView.subviews[0];//SPVideoView
        }

        if ([targetView isKindOfClass:%c(SPVideoView)]) {
            NSURL *url = nil; 
            SPPlayerWrapper *wrapper = MSHookIvar<SPPlayerWrapper *>(targetView,"_delegate");
            NSLog(@"kk | wrapper : %@",wrapper);
            if (wrapper) {
                SPMediaInfo *mediaInfo = [wrapper mediaInfo];
                if (mediaInfo) {
                    NSString *urlString = [mediaInfo url];
                    url = [NSURL URLWithString:urlString];
                    NSLog(@"kk | url : %@",url);
                    if (url && [url isKindOfClass:%c(NSURL)]) {
                        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                        downloadManager.delegate = self;
                        [downloadManager downloadVideoWithURL:url];   
                    }
                }
            }
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
static BOOL qqEnable = NO;
static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    qqEnable = [settings objectForKey:@"qqEnable"] ? [[settings objectForKey:@"qqEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (qqEnable)
    {
        NSLog(@"kk | 摇一摇");
        %init(_ungrouped);
    }
    
}