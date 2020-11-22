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
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:request.URL.lastPathComponent];
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:filePath]) {
            [fm removeItemAtPath:filePath error:nil];
        }
        [self _getFileTotalLengthWithURL:self.url.absoluteString completion:^(NSInteger length) {
            KKFileMultiDownloadCenter *dc = [[KKFileMultiDownloadCenter alloc] init];
            dc.delegate = self;
            [dc multiDownloadWithFileLength:length url:self.url filePath:(NSString *)filePath];
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
