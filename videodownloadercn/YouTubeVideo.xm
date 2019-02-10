#import <UIKit/UIKit.h>
#import "lib/DownloaderManager/DownloaderManager.h"
#import "lib/MBProgressHUD/MBProgressHUD.h"
#import "lib/YouTubeVideo/YouTubeVideo.h"

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

static double totalMediaTime = 0.f;
static BOOL isShow = NO;
static MBProgressHUD *hud = nil;

static NSString *audioFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VideoDownloaderCN.m4a"];
static NSString *videoFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VideoDownloaderCN.mp4"];

%hook YTContentVideoPlayerOverlayViewController

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

        //下载音频
        NSArray *selectableAudioFormats = [player selectableAudioFormats];
        for (id audioFormat in selectableAudioFormats) {
            MLFormat *mlFormat = (MLFormat *)audioFormat;
            YTIFormatStream *formatStream = [mlFormat formatStream];
            if ([formatStream itag] == 140)
            {
                NSString *audioURLString = [formatStream URL];
                NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:audioURLString]];
                NSString *string = [NSString stringWithFormat:@"bytes=%lu-",(unsigned long)0];
                [request setValue:string forHTTPHeaderField:@"Range"];
                NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
                downloadTask.taskDescription = @"audioTask";
                [downloadTask resume]; 
                break;
            }
        }

        //取视频画质与视频url
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"select video quality" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray *selectableVideoFormats = [player selectableVideoFormats];
        for (id videoFormat in selectableVideoFormats) {
            MLFormat *mlFormat = (MLFormat *)videoFormat;
            YTIFormatStream *formatStream = [mlFormat formatStream];
            NSString *qualityLabel = [formatStream qualityLabel];
            NSString *mimeType = [formatStream mimeType];
            if (qualityLabel && [mimeType containsString:@"video"]) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:qualityLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //取视频URL
                    NSString *urlString = [formatStream URL];
                    if (urlString) {
                        NSURL *videoFileURL = [NSURL URLWithString:urlString];  
                        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:videoFileURL];
                        NSString *string = [NSString stringWithFormat:@"bytes=%lu-",(unsigned long)0];
                        [request setValue:string forHTTPHeaderField:@"Range"];

                        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
                        [downloadTask resume];   
                    }
                }];
                [alertVC addAction:action];
            }
        }
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:cancel];
        [self presentViewController:alertVC animated:NO completion:nil];
    }
}

%new
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if ([downloadTask.taskDescription isEqualToString:@"audioTask"]) {

    }else {
        if (!isShow) {
            hud = [MBProgressHUD showHUDAddedTo:KEY_WINDOW animated:YES];
            hud.mode = MBProgressHUDModeDeterminate;
            hud.label.text = NSLocalizedString(@"Donwloading...", @"HUD loading title");
            NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:100];
            hud.progressObject = progressObject;
            [hud.button setTitle:NSLocalizedString(@"cancel", @"HUD cancel button title") forState:UIControlStateNormal];
            [hud.button addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(self, @selector(youtubeDownloadTask),
                             downloadTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            isShow = YES;
            NSLog(@"1");
        }
        float progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
        hud.progressObject.completedUnitCount = [@(progress * 100)  intValue];
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
}

%new
- (void)cancel {
    NSURLSessionDownloadTask *downloadTask = objc_getAssociatedObject(self, @selector(youtubeDownloadTask));
    [downloadTask cancel];
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        hud = nil;
        isShow = NO;
    });
}

%new 
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    if ([downloadTask.taskDescription isEqualToString:@"audioTask"]) {
        //移动下载的文件，否则会在临时目录被覆盖删除
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:audioFilePath] error:nil];
        NSLog(@"audioPath:%@",audioFilePath);
    }else {
        //移动下载的文件，否则会在临时目录被覆盖删除
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:videoFilePath] error:nil];
        NSLog(@"videoPath:%@",videoFilePath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:audioFilePath])
        {
            YouTubeVideo *video = [[YouTubeVideo alloc] init];
            video.compositionName = @"final.mp4";
            [video compositionVideoUrl:[NSURL fileURLWithPath:videoFilePath] videoTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake([@(totalMediaTime) intValue], 1)) audioUrl:[NSURL fileURLWithPath:audioFilePath] audioTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake([@(totalMediaTime) intValue], 1)) success:^(NSURL * _Nonnull fileUrl) {
                NSLog(@"合成成功,%@",fileUrl);
                NSString *filePath = [fileUrl path];
                NSLog(@"filePath:%@",filePath);
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    NSLog(@"1");
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }];
        }
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
}

%end
