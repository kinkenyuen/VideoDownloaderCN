//
//  VideoAudioComposition.h
//
//  Created by kinken on 2019/2/1.
//  Copyright © 2019 kinkenyuen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface VideoAudioComposition : NSObject

/**
 合成成功block
 
 @param fileUrl 合成后的地址
 */
typedef void(^SuccessBlcok)(NSURL *fileUrl);

/**
 进度block
 
 @param fileUrl 合成后的地址
 */
typedef void(^ProgressBlcok)(float progress);

@property (nonatomic,copy) ProgressBlcok progressBlock;

/**
 合成后的名字
 */
@property (nonatomic,copy) NSString *compositionName;

/**
 转换后的格式
 */
@property (nonatomic, copy) AVFileType outputFileType;

/**
 视频音频合成
 
 @param videoUrl 视频地址
 @param videoTimeRange 截取时间
 @param audioUrl 音频地址
 @param audioTimeRange 截取时间
 @param successBlcok 成功回调
 */
- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange audioUrl:(NSURL *)audioUrl audioTimeRange:(CMTimeRange)audioTimeRange success:(SuccessBlcok)successBlcok;

@end

NS_ASSUME_NONNULL_END
