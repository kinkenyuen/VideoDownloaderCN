//
//  KKFileMultiDownloadCenter.m
//  MultipleDownload
//
//  Created by ruanjianqin on 2020/11/13.
//  Copyright © 2020 ruanjianqin. All rights reserved.
//

#import "KKFileMultiDownloadCenter.h"

#define blockSize 1024*1024 * 10 //10MB

@interface KKFileMultiDownloadCenter () <NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, assign) long long totalFileLength;    //文件总长度
@property (nonatomic, assign) long long divideLength;       //拆分总长度
@property (nonatomic, assign) long long finishedLength;     //下载完成总长度
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSLock *lock;
@end

@implementation KKFileMultiDownloadCenter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.divideLength = 0;
        self.finishedLength = 0;
        self.queue = [[NSOperationQueue alloc] init];
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSURLSession *)session{
    if (_session == nil) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 300;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    }
    return _session;
}

- (void)multiDownloadWithFileLength:(NSInteger)fileLength url:(NSURL *)url filePath:(nonnull NSString *)filePath{
    self.totalFileLength = fileLength;
    self.filePath = filePath;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        [fm removeItemAtPath:filePath error:nil];
    }
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [self.fileHandle truncateFileAtOffset:fileLength];
    
    __weak NSOperationQueue *wQueue = self.queue;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        while (self.divideLength < fileLength) {
            long long startSize = self.divideLength;
            long long endSize = startSize + blockSize;
            if (endSize > fileLength) {
                endSize = fileLength - 1;
                self.divideLength = fileLength;
            } else {
                self.divideLength += blockSize;
            }
            
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                NSString *range=[NSString stringWithFormat:@"bytes=%lld-%lld", startSize, endSize];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                [request setValue:range forHTTPHeaderField:@"Range"];
                NSLog(@"requestHeader:%@", request.allHTTPHeaderFields);
                NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request];
                [task resume];
            }];
            [wQueue addOperation:operation];
        }
    }];
    [self.queue addOperation:op];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    long long startSize = 0;
    long long endSize = 0;
    if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *tmpResponse = (NSHTTPURLResponse *)downloadTask.response;
        NSDictionary *dic = tmpResponse.allHeaderFields;
        NSString *fileRange = dic[@"Content-Range"];
        fileRange = [fileRange stringByReplacingOccurrencesOfString:@"bytes" withString:@""];
        fileRange = [fileRange stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *aTmp1 = [fileRange componentsSeparatedByString:@"/"];
        NSArray *aTmp2 = @[];
        if (aTmp1.count) {
            NSString *tmpStr = aTmp1[0];
            aTmp2 = [tmpStr componentsSeparatedByString:@"-"];
            if (aTmp1.count >= 2) {
                NSString *startSizeStr = aTmp2[0];
                NSString *endSizeStr = aTmp2[1];
                startSize = startSizeStr.longLongValue;
                endSize = endSizeStr.longLongValue;
                
                NSData *downloadData = [NSData dataWithContentsOfURL:location];
                
                [self.lock lock];
                [self.fileHandle seekToFileOffset:startSize];
                [self.fileHandle writeData:downloadData];
                self.finishedLength += downloadData.length;
                double progress = self.finishedLength * 1.0 / self.totalFileLength;
                progress = progress >= 1 ? 1 : progress;
                if (progress == 1) {
                    if ([self.delegate respondsToSelector:@selector(multiDownloadDidFinished:)] && [self.delegate respondsToSelector:@selector(multiDownloadProgress:)]) {
                        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
                        [mainQueue addOperationWithBlock:^{
                            [self.delegate multiDownloadProgress:progress];
                            [self.delegate multiDownloadDidFinished:self.filePath];
                        }];
                    }
                }else{
                    if ([self.delegate respondsToSelector:@selector(multiDownloadProgress:)]) {
                        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
                        [mainQueue addOperationWithBlock:^{
                            [self.delegate multiDownloadProgress:progress];
                        }];
                    }
                }
                [self.lock unlock];
            }
        }
    }
}
@end
