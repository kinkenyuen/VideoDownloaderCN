//
//  YouTubeVideo.m
//  Test
//
//  Created by kinken on 2019/2/1.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import "YouTubeVideo.h"

@implementation YouTubeVideo

- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange audioUrl:(NSURL *)audioUrl audioTimeRange:(CMTimeRange)audioTimeRange success:(SuccessBlcok)successBlcok {
    
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    NSString *outPutFilePath = [filePath stringByAppendingPathComponent:_compositionName];
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    NSError *error;
    AVMutableCompositionTrack *audioCompostionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //音频文件资源
    AVURLAsset  *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    [audioCompostionTrack insertTimeRange:audioTimeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:&error];

    //视频文件资源
    AVMutableCompositionTrack *vedioCompostionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVURLAsset *vedioAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    [vedioCompostionTrack insertTimeRange:videoTimeRange ofTrack:[[vedioAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:&error];
    
    [self composition:mixComposition storePath:outPutFilePath success:successBlcok];
}

//输出
- (void)composition:(AVMutableComposition *)avComposition
          storePath:(NSString *)storePath
            success:(SuccessBlcok)successBlcok {
    AVAssetExportSession* assetExportSession = [[AVAssetExportSession alloc] initWithAsset:avComposition presetName:AVAssetExportPresetMediumQuality];
    assetExportSession.outputURL = [NSURL fileURLWithPath:storePath];
    assetExportSession.outputFileType = @"com.apple.quicktime-movie";
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlcok([NSURL fileURLWithPath:storePath]);
        });
    }];
}

@end
