#pragma mark - 微博国际版

#import <UIKit/UIKit.h>
#import "DownloaderManager.h"
#import "MBProgressHUD.h"
#import <Photos/Photos.h>

@interface WUWeiboStatus : NSObject
@property(retain, nonatomic) NSDictionary *pageInfoOri; 
@end

@interface NYASDetailCell : UITableViewCell
@property(retain, nonatomic) WUWeiboStatus *videoStatus; 
@end

@interface NYASVideoDetailVC : UIViewController <DownloaderManagerDelegeate>
@property(nonatomic) NYASDetailCell *currentCellNode;
- (void)downloadVideo;
@end

static BOOL isShow = NO;
static MBProgressHUD *hud = nil;

%hook NYASVideoDetailVC

- (void)viewDidLoad {
	%orig;
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.view addGestureRecognizer:longPressGesture];
}

%new 
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
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
- (void)downloadVideo
{
	NYASDetailCell *currentCellNode = [self currentCellNode];
	WUWeiboStatus *videoStatus = [currentCellNode videoStatus];
	NSDictionary *pageInfoOri = [videoStatus pageInfoOri];
	NSDictionary *mediaInfo = pageInfoOri[@"media_info"];
	NSString *mp4HDURL = mediaInfo[@"mp4_hd_url"];
	NSURL *url = [NSURL URLWithString:mp4HDURL];
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
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Downloading...", @"HUD loading title");
        NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
        hud.progressObject = progressObject;
        [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(weiBoInternationalDownloadTask),
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
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(weiBoInternationalDownloadTask));
    [downloadTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new
- (void)videoDidFinishDownloaded:(NSString * _Nonnull)filePath {
	[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
	    if (status == PHAuthorizationStatusAuthorized) {
	        //保存到系统相册
		    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
		        UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
		    }
	    }
    }];
}

%new
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Save Failed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
static BOOL weiboInternationalEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    weiboInternationalEnable = [settings objectForKey:@"weiboInternationalEnable"] ? [[settings objectForKey:@"weiboInternationalEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (weiboInternationalEnable)
    {
        %init(_ungrouped);
    }

}

