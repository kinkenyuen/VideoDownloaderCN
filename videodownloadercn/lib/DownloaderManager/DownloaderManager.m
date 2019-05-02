//
//  DownloaderManager.m
//  DownloaderManager
//
//  Created by kinken on 2019/1/27.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import "DownloaderManager.h"

@interface DownloaderManager() <NSURLSessionDelegate>

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

#pragma mark - download

- (void)downloadVideoWithURL:(NSURL *)url {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];

    // NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *string = [NSString stringWithFormat:@"bytes=%lu-",(unsigned long)0];
    [request setValue:string forHTTPHeaderField:@"Range"];

    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float value = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDownloadeProgress:downloadTask:)]) {
        [self.delegate videoDownloadeProgress:value downloadTask:downloadTask];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    //搞个时间戳来命名视频文件
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYYMMddHHmmss";
    NSString *dateString = [formatter stringFromDate:currentDate];
    
    NSString *filePath = nil;
    if (self.outputPath)
    {
        filePath = self.outputPath;
    }else {
        //默认沙盒路径
        filePath = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:@".mp4"];
    }
    
    //移动下载的文件，否则会在临时目录被覆盖删除
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];

    //回调下载文件路径给代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDidFinishDownloaded:)]) {
        [self.delegate videoDidFinishDownloaded:filePath];
    }
}

@end
