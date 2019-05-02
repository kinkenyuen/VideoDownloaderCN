//
//  DownloaderManager.h
//  DownloaderManager
//
//  Created by kinken on 2019/1/27.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DownloaderManagerDelegeate <NSObject>
/*下载完成回调*/
- (void)videoDidFinishDownloaded:(NSString * _Nonnull)filePath;

/**
 下载进度
 */
- (void)videoDownloadeProgress:(float)progress downloadTask:(NSURLSessionDownloadTask * _Nullable)downloadTask;

@end

NS_ASSUME_NONNULL_BEGIN

@interface DownloaderManager : NSObject
@property (nonatomic, strong) NSString *outputPath;
@property (nonatomic, weak) id<DownloaderManagerDelegeate> delegate;

+ (instancetype)sharedDownloaderManager;

- (void)downloadVideoWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
