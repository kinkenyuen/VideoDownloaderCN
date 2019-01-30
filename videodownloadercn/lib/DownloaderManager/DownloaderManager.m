//
//  DownloaderManager.m
//  Test
//
//  Created by kinken on 2019/1/27.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

// #define KEY_WINDOW [UIApplication sharedApplication].keyWindow

#import "DownloaderManager.h"
#import "../UAProgressView/UAProgressView.h"

@interface DownloaderManager() <NSURLSessionDelegate>
@property (nonatomic, strong) UAProgressView *progressView;
@property (nonatomic, strong) UIView *progressWindow;
@end

@implementation DownloaderManager

#pragma mark - single

static DownloaderManager* _instance = nil;

+ (instancetype)sharedDownloaderManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+(id) allocWithZone:(struct _NSZone *)zone
{
    return [DownloaderManager sharedDownloaderManager] ;
}

-(id) copyWithZone:(struct _NSZone *)zone
{
    return [DownloaderManager sharedDownloaderManager] ;
}

#pragma mark setter & getter

- (void)setProgressViewWindow:(UIView *)window {
    _progressWindow = window;
}


#pragma mark - download

- (void)downloadVideoWithURL:(NSURL *)url {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (!self.progressView)
    {
        UAProgressView *progressView = [[UAProgressView alloc] init];
        progressView.bounds = CGRectMake(0, 0, 100, 100);
        CGFloat x = self.progressWindow.bounds.size.width * 0.5;
        CGFloat y = self.progressWindow.bounds.size.height *0.5;
        CGPoint center = CGPointMake(x, y);
        progressView.center = center;
        progressView.lineWidth = 5;
        progressView.borderWidth = 1;
        self.progressView = progressView;
        
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
                self.progressView = nil;
            }
        };
        
        progressView.didSelectBlock = ^(UAProgressView *progressView) {
            [downloadTask cancel];
            [progressView removeFromSuperview];
            self.progressView = nil;
        };
        [self.progressWindow addSubview:progressView];
    }
    float value = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    self.progressView.progress = value;
}

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

    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDidFinishDownloaded)]) {
        [self.delegate videoDidFinishDownloaded];
    }
}

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

// - (UIWindow *)lastWindow {
//     NSArray *windows = [UIApplication sharedApplication].windows;
//     for (UIWindow *window in [windows reverseObjectEnumerator]) {
//         if ([window isKindOfClass:[UIWindow class]] && CGRectEqualToRect(window.bounds, [UIScreen mainScreen].bounds)) {
//             return window;
//         }
//     }
//     return [UIApplication sharedApplication].keyWindow;
// }

@end
