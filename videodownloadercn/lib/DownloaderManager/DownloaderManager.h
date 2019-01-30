//
//  DownloaderManager.h
//  Test
//
//  Created by kinken on 2019/1/27.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DownloaderManagerDelegeate <NSObject>
/*下载完成回调*/
- (void)videoDidFinishDownloaded;

@end

NS_ASSUME_NONNULL_BEGIN

@interface DownloaderManager : NSObject
@property (nonatomic, weak) id<DownloaderManagerDelegeate> delegate;

+ (instancetype)sharedDownloaderManager;

- (void)downloadVideoWithURL:(NSURL *)url;

- (void)setProgressViewWindow:(UIView *)window;
@end

NS_ASSUME_NONNULL_END
