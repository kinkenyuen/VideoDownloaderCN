#pragma mark - 网易云音乐视频

#import <UIKit/UIKit.h>

@interface NMDiscoveryVideoPlayView : UIView <UIAlertViewDelegate>
- (void)downloadVideoWithURL:(NSURL *)url;
@end

@interface NMDiscoverVideolistViewController : UIViewController
- (id)currentVideContextInfo;
@end

@interface NMShortVideo : NSObject
@end

@interface NMShortVideoUrlInfo : NSObject
@end

@interface NMVideoPlayView : UIView <UIAlertViewDelegate>
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
    NSLog(@"%s",__func__);
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
            NSLog(@"url:%@",url);
            /**
             拿到视频url下载
             */
            [self downloadVideoWithURL:url];
        }
    }
}

%new
- (void)downloadVideoWithURL:(NSURL *)url {
    if (url) {
        //            NSLog(@"urlHD:%@",url);
        //创建下载任务
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                    [alert show];
                });
            }else {
                //搞个时间戳来命名视频文件
                NSDate *currentDate = [NSDate date];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"YYYYMMddHHmmss";
                NSString *dateString = [formatter stringFromDate:currentDate];
                
                //沙盒路径
                NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:response.suggestedFilename];
                
                //移动下载的文件，否则会在临时目录被覆盖删除
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
                
                //保存到系统相册
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }
        }];
        //3.启动任务
        [downloadTask resume];
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
        //            NSLog(@"urlHD:%@",url);
        //创建下载任务
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                    [alert show];
                });
            }else {
                //搞个时间戳来命名视频文件
                NSDate *currentDate = [NSDate date];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"YYYYMMddHHmmss";
                NSString *dateString = [formatter stringFromDate:currentDate];
                
                //沙盒路径
                NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:response.suggestedFilename];
                
                //移动下载的文件，否则会在临时目录被覆盖删除
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
                
                //保存到系统相册
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }
        }];
        //3.启动任务
        [downloadTask resume];
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
static BOOL neteasemusicEnable = YES;

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
