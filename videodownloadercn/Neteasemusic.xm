#pragma mark - 网易云音乐视频

#import <UIKit/UIKit.h>
#import "lib/UAProgressView/UAProgressView.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow
#define LAST_WINDOW [[UIApplication sharedApplication].windows lastObject]

@interface NMDiscoveryVideoPlayView : UIView <UIAlertViewDelegate,NSURLSessionDelegate>
- (void)downloadVideoWithURL:(NSURL *)url;
@end

@interface NMDiscoverVideolistViewController : UIViewController
- (id)currentVideContextInfo;
@end

@interface NMShortVideo : NSObject
@end

@interface NMShortVideoUrlInfo : NSObject
@end

@interface NMVideoPlayView : UIView <UIAlertViewDelegate,NSURLSessionDelegate>
- (void)downloadVideoWithURL:(NSURL *)url;
@end

@interface NMVideoPlayController : UIViewController
@end

@interface NELivePlayerController : UIViewController
@end


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
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"下载该视频?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        [alert show];
    }
}

%new;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSURL *url = nil;
        //拿到对应cell上的视频url
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
            /**
             拿到视频url下载
             */
            [self downloadVideoWithURL:url];
        }
    }
}


/*由于进度条显示问题，单独将下载逻辑写在这里*/
%new
- (void)downloadVideoWithURL:(NSURL *)url {
    if (url) {
        //创建下载任务
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
        [downloadTask resume];
    }
}

static BOOL progressIsShow = 0;
%new
- (void)URLSession:(NSURLSession *)session 
downloadTask:(NSURLSessionDownloadTask *)downloadTask 
didWriteData:(int64_t)bytesWritten 
totalBytesWritten:(int64_t)totalBytesWritten 
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (!progressIsShow)
    {
        UAProgressView *progressView = [[UAProgressView alloc] init];
        progressView.bounds = CGRectMake(0, 0, 100, 100);
        progressView.center = KEY_WINDOW.center;
        progressView.lineWidth = 5;
        progressView.borderWidth = 1;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60.0, 20.0)];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setTextColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
        label.userInteractionEnabled = NO; // Allows tap to pass through to the progress view.
        progressView.centralView = label;

        progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f%%", progress * 100]];
            if (progress == 1.f)
            {
                [progressView removeFromSuperview];
                progressIsShow = 0;
            }
        };

        progressView.didSelectBlock = ^(UAProgressView *progressView) {
        [downloadTask cancel];
        [progressView removeFromSuperview];
        progressIsShow = 0;
        };


        objc_setAssociatedObject(self,@selector(wbProgressView),progressView,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [LAST_WINDOW addSubview:progressView];
        progressIsShow = 1;
    }
    float value = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    UAProgressView *progressView = objc_getAssociatedObject(self,@selector(wbProgressView));
    progressView.progress = value;
}

%new 
- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask 
      didFinishDownloadingToURL:(NSURL *)location {
        //搞个时间戳来命名视频文件
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"YYYYMMddHHmmss";
        NSString *dateString = [formatter stringFromDate:currentDate];

        //沙盒路径
        NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:@".mp4"];

        //移动下载的文件，否则会在临时目录被覆盖删除
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];

        //保存到系统相册
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
}

%new
/**
 移动到系统相册后回调
 */
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"已保存到系统相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    //移除沙盒的缓存文件
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
}

%end

#pragma mark - NMVideoPlayView

/**
 全屏播放视频下载
 */
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
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"下载该视频?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        [alert show];
    }
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
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
         情况2
         */
        NMVideoPlayController *targetVC = MSHookIvar<NMVideoPlayController *>(self, "_delegate");
        if ([targetVC isKindOfClass:%c(NMVideoPlayController)]) {
            url = MSHookIvar<NSURL *>(targetVC, "_videoUrl");
        }
        
        /**
         情况3
         */
        NELivePlayerController *nelPlayer = MSHookIvar<NELivePlayerController *>(targetVC, "_nelPlayer");
        if ([nelPlayer isKindOfClass:%c(NELivePlayerController)]) {
            NSString *_urlString = MSHookIvar<NSString *>(nelPlayer, "_urlString");
            if (_urlString) {
                url = [NSURL URLWithString:_urlString];
            }
        }
        /**
         拿到视频url下载
         */
        [self downloadVideoWithURL:url];
    }
}

%new
- (void)downloadVideoWithURL:(NSURL *)url {
    if (url) {
        //创建下载任务
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
        [downloadTask resume];
    }
}

static BOOL nmProgressIsShow = 0;
%new
- (void)URLSession:(NSURLSession *)session 
downloadTask:(NSURLSessionDownloadTask *)downloadTask 
didWriteData:(int64_t)bytesWritten 
totalBytesWritten:(int64_t)totalBytesWritten 
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (!nmProgressIsShow)
    {
        UAProgressView *progressView = [[UAProgressView alloc] init];
        progressView.bounds = CGRectMake(0, 0, 100, 100);
        progressView.center = KEY_WINDOW.center;
        progressView.lineWidth = 5;
        progressView.borderWidth = 1;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60.0, 20.0)];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setTextColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
        label.userInteractionEnabled = NO; // Allows tap to pass through to the progress view.
        progressView.centralView = label;

        progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress) {
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f%%", progress * 100]];
            if (progress == 1.f)
            {
                [progressView removeFromSuperview];
                nmProgressIsShow = 0;
            }
        };

        progressView.didSelectBlock = ^(UAProgressView *progressView) {
        [downloadTask cancel];
        [progressView removeFromSuperview];
        nmProgressIsShow = 0;
        };

        objc_setAssociatedObject(self,@selector(wbProgressView),progressView,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [LAST_WINDOW addSubview:progressView];
        nmProgressIsShow = 1;
    }
    float value = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    UAProgressView *progressView = objc_getAssociatedObject(self,@selector(wbProgressView));
    progressView.progress = value;
}

%new 
- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask 
      didFinishDownloadingToURL:(NSURL *)location {
        //搞个时间戳来命名视频文件
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"YYYYMMddHHmmss";
        NSString *dateString = [formatter stringFromDate:currentDate];

        //沙盒路径
        NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:@".mp4"];

        //移动下载的文件，否则会在临时目录被覆盖删除
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];

        //保存到系统相册
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
}

%new
/**
 移动到系统相册后回调
 */
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"已保存到系统相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
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
