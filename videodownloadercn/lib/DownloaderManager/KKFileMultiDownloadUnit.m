//
//  KKFileMultiDownloadUnit.m
//  MultipleDownload
//
//  Created by ruanjianqin on 2020/11/13.
//  Copyright © 2020 ruanjianqin. All rights reserved.
//

#import "KKFileMultiDownloadUnit.h"
#import "KKFileMultiDownloadCenter.h"

@interface KKFileMultiDownloadUnit () <KKFileMultiDownloadCenterDelegate>

@end

@implementation KKFileMultiDownloadUnit
- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.url = url;
    }
    return self;
}

- (void)startMultiDownload {
    if (self.url && [self.url isKindOfClass:[NSURL class]]) {
        NSDate *date = [[NSDate alloc] init];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYYMMddHHmmss"];
        NSString *fileName = [formatter stringFromDate:date];
        if (nil == _outputPath) {
            _outputPath = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName] stringByAppendingPathComponent:@".mp4"];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:_outputPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_outputPath error:nil];
        }
        [self _getFileTotalLengthWithURL:self.url.absoluteString completion:^(NSInteger length) {
            KKFileMultiDownloadCenter *dc = [[KKFileMultiDownloadCenter alloc] init];
            dc.delegate = self;
            [dc multiDownloadWithFileLength:length url:self.url filePath:(NSString *)_outputPath];
        }];
    }
}

- (void)_getFileTotalLengthWithURL:(NSString *)url
                       completion:(void(^)(NSInteger length))completion{
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"HEAD";
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *tmpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"allHeaderFields:%@", tmpResponse.allHeaderFields);
        }
        NSInteger fileTotalLength = response.expectedContentLength;
        completion(fileTotalLength);
    }];
    [dataTask resume];
}

#pragma mark - KKFileMultiDownloadCenterDelegate

- (void)multiDownloadProgress:(double)progress {
    if ([self.delegate respondsToSelector:@selector(downloadTaskProgress:)]) {
        [self.delegate downloadTaskProgress:progress];
    }
}

- (void)multiDownloadDidFinished:(NSString *)filePath {
    if ([self.delegate respondsToSelector:@selector(downloadTaskDidFinishWithSavePath:)]) {
        [self.delegate downloadTaskDidFinishWithSavePath:filePath];
    }
}

@end
