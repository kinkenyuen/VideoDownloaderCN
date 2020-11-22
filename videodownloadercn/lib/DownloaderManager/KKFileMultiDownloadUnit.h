//
//  KKFileMultiDownloadUnit.h
//  MultipleDownload
//
//  Created by ruanjianqin on 2020/11/13.
//  Copyright © 2020 ruanjianqin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KKFileMultiDownloadUnitDelegate <NSObject>
- (void)downloadTaskProgress:(double)progress;
- (void)downloadTaskDidFinishWithSavePath:(NSString *)savePath;

@end

@interface KKFileMultiDownloadUnit : NSObject
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, copy) NSString *outputPath;
@property(nonatomic, weak) id <KKFileMultiDownloadUnitDelegate> delegate;
- (nonnull instancetype)initWithURL:(NSURL *)url;
- (void)startMultiDownload;
@end

NS_ASSUME_NONNULL_END
