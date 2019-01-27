//
//  DownloaderManager.h
//  Test
//
//  Created by kinken on 2019/1/27.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DownloaderManager : NSObject

+ (instancetype)sharedDownloaderManager;

- (void)downloadVideoWithURL:(NSURL *)url;

- (void)setProgressViewWindow:(UIView *)window;
@end

NS_ASSUME_NONNULL_END
