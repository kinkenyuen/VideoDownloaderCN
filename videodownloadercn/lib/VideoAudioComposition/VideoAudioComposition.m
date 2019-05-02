//
//  VideoAudioComposition.m
//
//  Created by kinken on 2019/2/1.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import "VideoAudioComposition.h"

@interface VideoAudioComposition()
@property (nonatomic, strong) AVAssetExportSession *assetExport;
@property (nonatomic, strong) NSTimer *exportProgressTimer;
@end

@implementation VideoAudioComposition

- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange audioUrl:(NSURL *)audioUrl audioTimeRange:(CMTimeRange)audioTimeRange success:(SuccessBlcok)successBlcok {
    
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    NSString *outPutFilePath = [filePath stringByAppendingPathComponent:_compositionName];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    //音频采集轨道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //视频采集轨道
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    [self composition:composition storePath:outPutFilePath success:successBlcok];
}

//输出
- (void)composition:(AVMutableComposition *)avComposition
          storePath:(NSString *)storePath
            success:(SuccessBlcok)successBlcok {
    self.assetExport = [[AVAssetExportSession alloc] initWithAsset:avComposition presetName:AVAssetExportPresetHighestQuality];
    self.assetExport.outputFileType = AVFileTypeMPEG4;
    self.assetExport.outputURL = [NSURL fileURLWithPath:storePath];
    self.assetExport.shouldOptimizeForNetworkUse = YES;
    //要用定时器监听进度，不能用KVO
    self.exportProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateExportDisplay) userInfo:nil repeats:YES];
    [self.assetExport exportAsynchronouslyWithCompletionHandler:^{
        switch (self.assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"%@", [NSString stringWithFormat:@"exporter Failed%@",self.assetExport.error.description]);
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlcok([NSURL fileURLWithPath:storePath]);
                });
                break;
        }
    }];
}

- (void)updateExportDisplay {
    if (self.progressBlock)
    {
        self.progressBlock(self.assetExport.progress);
    }
    if (self.assetExport.status == AVAssetExportSessionStatusCompleted || self.assetExport.progress >= 1.f) {
        [self.exportProgressTimer invalidate];
        self.exportProgressTimer = nil;
    }
}

@end
