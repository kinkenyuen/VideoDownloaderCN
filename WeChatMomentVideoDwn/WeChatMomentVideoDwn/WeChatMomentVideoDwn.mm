#line 1 "/Users/kinken_yuen/Desktop/WeChatMomentVideoDwn/WeChatMomentVideoDwn/WeChatMomentVideoDwn.xm"


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





#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class WCStoryPreviewPageView; @class WCStoryMediaItem; @class WCActionSheet; 
static WCStoryPreviewPageView* (*_logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$)(_LOGOS_SELF_TYPE_INIT WCStoryPreviewPageView*, SEL, struct CGRect, id, _Bool) _LOGOS_RETURN_RETAINED; static WCStoryPreviewPageView* _logos_method$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(_LOGOS_SELF_TYPE_INIT WCStoryPreviewPageView*, SEL, struct CGRect, id, _Bool) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$_ungrouped$WCStoryPreviewPageView$actionSheet$clickedButtonAtIndex$)(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST, SEL, id, long long); static void _logos_method$_ungrouped$WCStoryPreviewPageView$actionSheet$clickedButtonAtIndex$(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST, SEL, id, long long); static void _logos_method$_ungrouped$WCStoryPreviewPageView$onShowAlertViewOfDwn(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$)(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST, SEL, NSString *, NSError *, void *); static void _logos_method$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST, SEL, NSString *, NSError *, void *); static WCActionSheet* (*_logos_orig$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$)(_LOGOS_SELF_TYPE_INIT WCActionSheet*, SEL, id, id, id, id, id) _LOGOS_RETURN_RETAINED; static WCActionSheet* _logos_method$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$(_LOGOS_SELF_TYPE_INIT WCActionSheet*, SEL, id, id, id, id, id) _LOGOS_RETURN_RETAINED; 
static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryPreviewPageView(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryPreviewPageView"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryMediaItem(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryMediaItem"); } return _klass; }
#line 26 "/Users/kinken_yuen/Desktop/WeChatMomentVideoDwn/WeChatMomentVideoDwn/WeChatMomentVideoDwn.xm"


static WCStoryPreviewPageView* _logos_method$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(_LOGOS_SELF_TYPE_INIT WCStoryPreviewPageView* __unused self, SEL __unused _cmd, struct CGRect arg1, id arg2, _Bool arg3) _LOGOS_RETURN_RETAINED {
    
    id wcStoryPreviewPageView = _logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(self, _cmd, arg1, arg2, arg3);
    if (wcStoryPreviewPageView) {
        UILongPressGestureRecognizer *LongPressG = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressSelf:)];
        [wcStoryPreviewPageView addGestureRecognizer:LongPressG];
    }
    return wcStoryPreviewPageView;
}

static void _logos_method$_ungrouped$WCStoryPreviewPageView$actionSheet$clickedButtonAtIndex$(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, long long arg2) {
    if (arg2 == 0) {
        [self onShowAlertViewOfDwn];
    }
    _logos_orig$_ungrouped$WCStoryPreviewPageView$actionSheet$clickedButtonAtIndex$(self, _cmd, arg1, arg2);
}


static void _logos_method$_ungrouped$WCStoryPreviewPageView$onShowAlertViewOfDwn(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
    WCStoryDataItem *dataItem = MSHookIvar<WCStoryDataItem *>(self, "m_dataItem");
    WCStoryMediaItem *mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
    NSLog(@"Video URL:%@",[mediaItem videoUrl]);
    if (mediaItem && [mediaItem isKindOfClass:_logos_static_class_lookup$WCStoryMediaItem()]) {
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
                
                NSDate *currentDate = [NSDate date];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"YYYYMMddHHmmss";
                NSString *dateString = [formatter stringFromDate:currentDate];
                
                
                
                NSString *filePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dateString] stringByAppendingString:response.suggestedFilename];
                
                NSLog(@"path:%@",filePath);
                
                
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];
                
                
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }
        }];
        
        [downloadTask resume];
    }
}




static void _logos_method$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * videoPath, NSError * error, void * contextInfo) {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"下载失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"已保存到系统相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
}





static WCActionSheet* _logos_method$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$(_LOGOS_SELF_TYPE_INIT WCActionSheet* __unused self, SEL __unused _cmd, id arg1, id arg2, id arg3, id arg4, id arg5) _LOGOS_RETURN_RETAINED {
    if ([arg2 isKindOfClass:_logos_static_class_lookup$WCStoryPreviewPageView()]) {
        id aSheet = _logos_orig$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$(self, _cmd, arg1,arg2,arg3,arg4,arg5);
        [aSheet addButtonWithTitle:@"下载视频"];
        return aSheet;
    }else {
        return _logos_orig$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$(self, _cmd, arg1, arg2, arg3, arg4, arg5);
    }
}

static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$WCStoryPreviewPageView = objc_getClass("WCStoryPreviewPageView"); MSHookMessageEx(_logos_class$_ungrouped$WCStoryPreviewPageView, @selector(initWithFrame:dataItem:canDeleteMyOwnStory:), (IMP)&_logos_method$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$, (IMP*)&_logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$);MSHookMessageEx(_logos_class$_ungrouped$WCStoryPreviewPageView, @selector(actionSheet:clickedButtonAtIndex:), (IMP)&_logos_method$_ungrouped$WCStoryPreviewPageView$actionSheet$clickedButtonAtIndex$, (IMP*)&_logos_orig$_ungrouped$WCStoryPreviewPageView$actionSheet$clickedButtonAtIndex$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$WCStoryPreviewPageView, @selector(onShowAlertViewOfDwn), (IMP)&_logos_method$_ungrouped$WCStoryPreviewPageView$onShowAlertViewOfDwn, _typeEncoding); }MSHookMessageEx(_logos_class$_ungrouped$WCStoryPreviewPageView, @selector(video:didFinishSavingWithError:contextInfo:), (IMP)&_logos_method$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$, (IMP*)&_logos_orig$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$);Class _logos_class$_ungrouped$WCActionSheet = objc_getClass("WCActionSheet"); MSHookMessageEx(_logos_class$_ungrouped$WCActionSheet, @selector(initWithTitle:delegate:cancelButtonTitle:destructiveButtonTitle:otherButtonTitles:), (IMP)&_logos_method$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$, (IMP*)&_logos_orig$_ungrouped$WCActionSheet$initWithTitle$delegate$cancelButtonTitle$destructiveButtonTitle$otherButtonTitles$);} }
#line 118 "/Users/kinken_yuen/Desktop/WeChatMomentVideoDwn/WeChatMomentVideoDwn/WeChatMomentVideoDwn.xm"
