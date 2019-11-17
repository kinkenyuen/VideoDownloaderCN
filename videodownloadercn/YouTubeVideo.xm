#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "lib/DownloaderManager/DownloaderManager.h"
#import "lib/MBProgressHUD/MBProgressHUD.h"
#import "lib/VideoAudioComposition/VideoAudioComposition.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface MLHAMPlayer
@property(readonly, nonatomic) NSArray *selectableAudioFormats;
@property(readonly, nonatomic) NSArray *selectableVideoFormats;
@property(readonly, nonatomic) double totalMediaTime;
@end

@interface MLNerdStatsPlaybackData
@property(readonly, nonatomic) MLHAMPlayer *player;

@end

@interface YTContentVideoPlayerOverlayViewController : UIViewController <DownloaderManagerDelegeate, NSURLSessionDelegate>
@property(retain, nonatomic) MLNerdStatsPlaybackData *nerdStatsPlaybackData;
@property(nonatomic, strong)NSURL *audioURL;
@property(nonatomic, strong)NSURL *videoURL;
@end

@interface YTIFormatStream
@property(nonatomic) int itag;
@property(copy, nonatomic) NSString *URL;
@property(copy, nonatomic) NSString *qualityLabel;
@property(copy, nonatomic) NSString *mimeType;

@end

@interface MLFormat
@property(readonly, nonatomic) YTIFormatStream *formatStream;
@end

static double totalMediaTime = 0.f; //视频时间长度
static BOOL isAllDownloadTaskFinish = NO;   //下载任务完成标记
static BOOL isShow = NO;    //hud显示标记
static MBProgressHUD *hud = nil;    
static int currentProgress = 0; //100表示完成一个任务，叠加
static NSString *audioFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VideoDownloaderCN.m4a"];
static NSString *videoFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VideoDownloaderCN.mp4"];

%hook YTContentVideoPlayerOverlayViewController
%property(nonatomic, strong)NSURL *audioURL;
%property(nonatomic, strong)NSURL *videoURL;

- (void)viewDidLoad {
    %orig;
    if ([self.view isKindOfClass:%c(YTContentVideoPlayerOverlayView)]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self.view addGestureRecognizer:longPress];
    }
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        MLNerdStatsPlaybackData *nerdStatsPlaybackData = [self nerdStatsPlaybackData];
        MLHAMPlayer *player = [nerdStatsPlaybackData player];
        totalMediaTime = [player totalMediaTime];

        //获取音频URL
        NSArray *selectableAudioFormats = [player selectableAudioFormats];
        for (id audioFormat in selectableAudioFormats) {
            MLFormat *mlFormat = (MLFormat *)audioFormat;
            YTIFormatStream *formatStream = [mlFormat formatStream];
            if ([formatStream itag] == 140)
            {
                NSString *audioURLString = [formatStream URL];
                self.audioURL = [NSURL URLWithString:audioURLString];
                break;
            }
        }

        //取视频画质与视频URL
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"select video quality" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray *selectableVideoFormats = [player selectableVideoFormats];
        for (id videoFormat in selectableVideoFormats) {
            MLFormat *mlFormat = (MLFormat *)videoFormat;
            YTIFormatStream *formatStream = [mlFormat formatStream];
            NSString *qualityLabel = [formatStream qualityLabel];
            NSString *mimeType = [formatStream mimeType];
            if (qualityLabel && [mimeType containsString:@"video"]) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:qualityLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *urlString = [formatStream URL];
                    if (urlString) {
                        self.videoURL = [NSURL URLWithString:urlString];  
                        //先下载音频再下载视频
                        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
                        downloadManager.outputPath = audioFilePath;
                        downloadManager.delegate = self;
                        [downloadManager downloadVideoWithURL:self.audioURL];  
                    }
                }];
                [alertVC addAction:action];
            }
        }
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:cancel];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

%new
- (void)videoDownloadeProgress:(float)progress downloadTask:(NSURLSessionDownloadTask * _Nullable)downloadTask {
    if (!isShow)
    {
        hud = [MBProgressHUD showHUDAddedTo:KEY_WINDOW animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Downloading...", @"HUD loading title");
        NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:300];
        hud.progressObject = progressObject;
        [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        isShow = YES;
    }
    objc_setAssociatedObject(self, @selector(ytDownloadTask),
                         downloadTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    hud.progressObject.completedUnitCount = [@(progress * 100) intValue] + currentProgress;
    hud.detailsLabel.text = [NSString stringWithFormat:@"%lld%%",hud.progressObject.completedUnitCount / 3];
}

%new
- (void)cancel {
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(ytDownloadTask));
    [downloadTask cancel];
    isAllDownloadTaskFinish = NO;
    currentProgress = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new
- (void)videoDidFinishDownloaded:(NSString * _Nonnull)filePath {
    if ([filePath isEqualToString:videoFilePath])
    {
        //所有下载任务完成
        isAllDownloadTaskFinish = YES;
        currentProgress += 100;
    }

    if (isAllDownloadTaskFinish == NO)
    {
        //下载视频
        DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
        downloadManager.outputPath = videoFilePath;
        downloadManager.delegate = self;
        [downloadManager downloadVideoWithURL:self.videoURL]; 
        currentProgress += 100; 
    }else {
        //合成视频
        VideoAudioComposition *vaComposition = [[VideoAudioComposition alloc] init];
        //合成后的文件名
        vaComposition.compositionName = @"youtubeVideo.mp4";
        vaComposition.outputFileType = AVFileTypeMPEG4;
        vaComposition.progressBlock = ^(float progress) {
            hud.progressObject.completedUnitCount = [@(progress * 100) intValue] + currentProgress;
            hud.detailsLabel.text = [NSString stringWithFormat:@"%lld%%",hud.progressObject.completedUnitCount / 3];
            if (hud.progressObject.fractionCompleted >= 1.f)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    hud = nil;
                    isShow = NO;
                });
            }
        };
        CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake((int)totalMediaTime + 1,1));
        [vaComposition compositionVideoUrl:[NSURL fileURLWithPath:videoFilePath] videoTimeRange:videoTimeRange audioUrl:[NSURL fileURLWithPath:audioFilePath] audioTimeRange:videoTimeRange success:^(NSURL *fileUrl){
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized)
                {
                    //保存到系统相册
                    NSString *path = [fileUrl path];
                    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                    }
                }
            }];
        }];
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
    [[NSFileManager defaultManager] removeItemAtPath:audioFilePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:videoFilePath error:nil];

    //重置标记
    isAllDownloadTaskFinish = NO;
    currentProgress = 0;
}

%end

/**
 插件开关
 */
static BOOL ytEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    ytEnable = [settings objectForKey:@"ytEnable"] ? [[settings objectForKey:@"ytEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (ytEnable)
    {
        %init(_ungrouped);
    }
    
}

