//
//  KKFileMultiDownloadCenter.h
//  MultipleDownload
//
//  Created by ruanjianqin on 2020/11/13.
//  Copyright © 2020 ruanjianqin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KKFileMultiDownloadCenterDelegate <NSObject>
@required
- (void)multiDownloadProgress:(double)progress;
- (void)multiDownloadDidFinished:(NSString *)filePath;
@end

@interface KKFileMultiDownloadCenter : NSObject
@property(nonatomic, weak) id <KKFileMultiDownloadCenterDelegate> delegate;
- (void)multiDownloadWithFileLength:(NSInteger)fileLength url:(NSURL *)url filePath:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
