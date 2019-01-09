// See http://iphonedevwiki.net/index.php/Logos

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>

@interface WCStoryPreviewPageView
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)onShowAlertViewOfDwn;

@end

@interface WCStoryMediaItem : NSObject
@property(retain, nonatomic) NSString *videoUrl;

@end

@class WCStoryDataUnit,WCStoryDataItem;

/**
 下载即刻视频
 */
%hook WCStoryPreviewPageView

- (id)initWithFrame:(struct CGRect)arg1 dataItem:(id)arg2 canDeleteMyOwnStory:(_Bool)arg3 {
    //添加一个手势弹出下载按钮
    id wcStoryPreviewPageView = %orig;
    if (wcStoryPreviewPageView) {
        UILongPressGestureRecognizer *LongPressG = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressSelf:)];
        [wcStoryPreviewPageView addGestureRecognizer:LongPressG];
    }
    return wcStoryPreviewPageView;
}

- (void)actionSheet:(id)arg1 clickedButtonAtIndex:(long long)arg2 {
    if (arg2 == 0) {
        [self onShowAlertViewOfDwn];
    }
    %orig;
}

%new
- (void)onShowAlertViewOfDwn {
    //每一个时刻视频的信息
    WCStoryDataItem *dataItem = MSHookIvar<WCStoryDataItem *>(self, "m_dataItem");
    WCStoryMediaItem *mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
    NSLog(@"Video URL:%@",[mediaItem videoUrl]);
    if (mediaItem && [mediaItem isKindOfClass:%c(WCStoryMediaItem)]) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURL *url = [NSURL URLWithString:[mediaItem videoUrl]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                    [alert show];
                });
            }else {
                //搞个时间戳来命名文件
                NSDate *currentDate = [NSDate date];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"YYYYMMddHHmmss";
                NSString *dateString = [formatter stringFromDate:currentDate];
                
                
                //目标保存文件路径
                NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:response.suggestedFilename];
                
                NSLog(@"path:%@",filePath);
                
                //移动下载的文件，否则会在临时目录被覆盖删除
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
                
                //保存到系统相册
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }
        }];
        //3.启动任务
        [downloadTask resume];
    }
}

/**
 移动到系统相册后回调
 */
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"已保存到系统相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    //移除沙盒的缓存文件
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
}

%end

%hook WCActionSheet
//添加下载视频条目
- (id)initWithTitle:(id)arg1 delegate:(id)arg2 cancelButtonTitle:(id)arg3 destructiveButtonTitle:(id)arg4 otherButtonTitles:(id)arg5 {
    if ([arg2 isKindOfClass:%c(WCStoryPreviewPageView)]) {
        id aSheet = %orig(arg1,arg2,arg3,arg4,arg5);
        [aSheet addButtonWithTitle:@"下载视频"];
        return aSheet;
    }else {
        return %orig;
    }
}
%end
