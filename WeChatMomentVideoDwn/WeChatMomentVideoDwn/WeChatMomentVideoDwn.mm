#line 1 "/Users/kinken_yuen/Desktop/WeChatMomentVideoDwn1-.0.1/WeChatMomentVideoDwn/WeChatMomentVideoDwn.xm"


#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <UIKit/UIKit.h>
@interface WCStoryPreviewPageView : NSObject
@property(nonatomic,assign) BOOL canDeleteMyOwnStory;

- (void)onShowDownloadAlert;
@end

@interface WCStoryActionToolBar
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)addButtonWithTitle:(id)arg1 iconName:(id)arg2 isDestructive:(_Bool)arg3 handler:(id)arg4;
- (void)onShowAlertViewOfDwn;
@end

@interface WCStoryPreivewPageCollectionController : NSObject
@end

@interface WCStoryDataUnit : NSObject
@property(retain, nonatomic) NSMutableArray *storyDataItemArray;
@end

@interface WCStoryDataItem : NSObject
@end

@interface WCStoryMediaItem : NSObject
@property(retain, nonatomic) NSString *videoUrl;
@end

@interface WCStoryMultiContactPreviewCell : NSObject
@end





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

@class WCStoryMultiContactPreviewViewController; @class WCStoryPreviewPageView; @class WCStoryActionToolBar; @class WCStoryMediaItem; @class WCStoryDataItem; @class UIButton; @class WCStoryMultiContactPreviewCell; @class WCStoryDataUnit; @class WCStorysPreviewViewController; 
static WCStoryPreviewPageView* (*_logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$)(_LOGOS_SELF_TYPE_INIT WCStoryPreviewPageView*, SEL, struct CGRect, id, _Bool) _LOGOS_RETURN_RETAINED; static WCStoryPreviewPageView* _logos_method$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(_LOGOS_SELF_TYPE_INIT WCStoryPreviewPageView*, SEL, struct CGRect, id, _Bool) _LOGOS_RETURN_RETAINED; static void _logos_method$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$(_LOGOS_SELF_TYPE_NORMAL WCStoryPreviewPageView* _LOGOS_SELF_CONST, SEL, NSString *, NSError *, void *); static WCStoryActionToolBar* (*_logos_orig$_ungrouped$WCStoryActionToolBar$initWithFrame$)(_LOGOS_SELF_TYPE_INIT WCStoryActionToolBar*, SEL, struct CGRect) _LOGOS_RETURN_RETAINED; static WCStoryActionToolBar* _logos_method$_ungrouped$WCStoryActionToolBar$initWithFrame$(_LOGOS_SELF_TYPE_INIT WCStoryActionToolBar*, SEL, struct CGRect) _LOGOS_RETURN_RETAINED; static void _logos_method$_ungrouped$WCStoryActionToolBar$onShowAlertViewOfDwn(_LOGOS_SELF_TYPE_NORMAL WCStoryActionToolBar* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$UIButton$setImage$forState$)(_LOGOS_SELF_TYPE_NORMAL UIButton* _LOGOS_SELF_CONST, SEL, UIImage *, UIControlState); static void _logos_method$_ungrouped$UIButton$setImage$forState$(_LOGOS_SELF_TYPE_NORMAL UIButton* _LOGOS_SELF_CONST, SEL, UIImage *, UIControlState); 
static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryMediaItem(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryMediaItem"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStorysPreviewViewController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStorysPreviewViewController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryDataUnit(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryDataUnit"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryMultiContactPreviewCell(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryMultiContactPreviewCell"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryDataItem(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryDataItem"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$WCStoryMultiContactPreviewViewController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("WCStoryMultiContactPreviewViewController"); } return _klass; }
#line 41 "/Users/kinken_yuen/Desktop/WeChatMomentVideoDwn1-.0.1/WeChatMomentVideoDwn/WeChatMomentVideoDwn.xm"


static WCStoryPreviewPageView* _logos_method$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(_LOGOS_SELF_TYPE_INIT WCStoryPreviewPageView* __unused self, SEL __unused _cmd, struct CGRect arg1, id arg2, _Bool arg3) _LOGOS_RETURN_RETAINED {
    NSLog(@"%s",__func__);
    HBLogDebug(@"-[<WCStoryPreviewPageView: %p> initWithFrame:-- dataItem:%@ canDeleteMyOwnStory:%d]", self, arg2, arg3);
    
    id wcStoryPreviewPageView = _logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(self, _cmd, arg1, arg2, arg3);
    if (wcStoryPreviewPageView && arg3 == 0) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onShowActionSheet)];
        [wcStoryPreviewPageView addGestureRecognizer:tapGesture];
    }
    return _logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$(self, _cmd, arg1, arg2, arg3);
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







static WCStoryActionToolBar* _logos_method$_ungrouped$WCStoryActionToolBar$initWithFrame$(_LOGOS_SELF_TYPE_INIT WCStoryActionToolBar* __unused self, SEL __unused _cmd, struct CGRect arg1) _LOGOS_RETURN_RETAINED {
    id ToolBar = _logos_orig$_ungrouped$WCStoryActionToolBar$initWithFrame$(self, _cmd, arg1);
    __weak typeof(self) weakSelf = self;
    [ToolBar addButtonWithTitle:@"下载视频" iconName:@"dwn" isDestructive:NO handler:^{
        [weakSelf onShowAlertViewOfDwn];
    }];
    return ToolBar;
}





static void _logos_method$_ungrouped$WCStoryActionToolBar$onShowAlertViewOfDwn(_LOGOS_SELF_TYPE_NORMAL WCStoryActionToolBar* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    
    id targetVC = [[self nextResponder] nextResponder];
    
    WCStoryMediaItem *mediaItem = nil;
    
    WCStoryPreviewPageView *wcStoryPreviewPageView = nil;
    
    if ([targetVC isKindOfClass:_logos_static_class_lookup$WCStorysPreviewViewController()]) {
        WCStoryPreivewPageCollectionController *m_collectionController = MSHookIvar<WCStoryPreivewPageCollectionController *>(targetVC, "m_collectionController");
        wcStoryPreviewPageView = MSHookIvar<WCStoryPreviewPageView *>(m_collectionController, "m_playingPageView");
        WCStoryDataUnit *_dataUnit = MSHookIvar<WCStoryDataUnit *>(m_collectionController, "_dataUnit");
        NSMutableArray *storyDataItemArray = [_dataUnit storyDataItemArray];
        WCStoryDataItem *dataItem = storyDataItemArray[0];
        if ([dataItem isKindOfClass:_logos_static_class_lookup$WCStoryDataItem()]) {
            mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
        }
    }else if ([targetVC isKindOfClass:_logos_static_class_lookup$WCStoryMultiContactPreviewViewController()]) {
        UICollectionView *m_collectionView = MSHookIvar<UICollectionView *>(targetVC, "m_collectionView");
        UIView *cellView =[m_collectionView subviews][0];
        if ([cellView isKindOfClass:_logos_static_class_lookup$WCStoryMultiContactPreviewCell()]) {
            WCStoryPreivewPageCollectionController *_controller = MSHookIvar<WCStoryPreivewPageCollectionController *>(cellView, "_controller");;
            wcStoryPreviewPageView = MSHookIvar<WCStoryPreviewPageView *>(_controller, "m_playingPageView");
        }
        
        NSMutableArray *_dataUnitArray = MSHookIvar<NSMutableArray *>(targetVC, "_dataUnitArray");
        WCStoryDataUnit *dataUnit = _dataUnitArray[0];
        if ([dataUnit isKindOfClass:_logos_static_class_lookup$WCStoryDataUnit()]) {
            NSMutableArray *_storyDataItemArray = MSHookIvar<NSMutableArray *>(dataUnit, "_storyDataItemArray");
            WCStoryDataItem *dataItem = _storyDataItemArray[0];
            if ([dataItem isKindOfClass:_logos_static_class_lookup$WCStoryDataItem()]) {
                mediaItem = MSHookIvar<WCStoryMediaItem *>(dataItem, "_mediaItem");
            }
        }
    }
    
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

                
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];

                
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, wcStoryPreviewPageView, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                }
            }
        }];
        
        [downloadTask resume];
    }
}








static void _logos_method$_ungrouped$UIButton$setImage$forState$(_LOGOS_SELF_TYPE_NORMAL UIButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIImage * image, UIControlState state) {
    if ([[[self titleLabel] text] isEqualToString:@"下载视频"]) {
        NSString *strRecBundle = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
        NSString *strC = [[NSBundle bundleWithPath:strRecBundle] pathForResource:@"dwn" ofType:@"png" inDirectory:@"image"];
        UIImage *icon = [UIImage imageWithContentsOfFile:strC];
        _logos_orig$_ungrouped$UIButton$setImage$forState$(self, _cmd, (icon ? : image),state);
    }else {
        _logos_orig$_ungrouped$UIButton$setImage$forState$(self, _cmd, image, state);
    }
}



static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$WCStoryPreviewPageView = objc_getClass("WCStoryPreviewPageView"); MSHookMessageEx(_logos_class$_ungrouped$WCStoryPreviewPageView, @selector(initWithFrame:dataItem:canDeleteMyOwnStory:), (IMP)&_logos_method$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$, (IMP*)&_logos_orig$_ungrouped$WCStoryPreviewPageView$initWithFrame$dataItem$canDeleteMyOwnStory$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSString *), strlen(@encode(NSString *))); i += strlen(@encode(NSString *)); memcpy(_typeEncoding + i, @encode(NSError *), strlen(@encode(NSError *))); i += strlen(@encode(NSError *)); _typeEncoding[i] = '^'; _typeEncoding[i + 1] = 'v'; i += 2; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$WCStoryPreviewPageView, @selector(video:didFinishSavingWithError:contextInfo:), (IMP)&_logos_method$_ungrouped$WCStoryPreviewPageView$video$didFinishSavingWithError$contextInfo$, _typeEncoding); }Class _logos_class$_ungrouped$WCStoryActionToolBar = objc_getClass("WCStoryActionToolBar"); MSHookMessageEx(_logos_class$_ungrouped$WCStoryActionToolBar, @selector(initWithFrame:), (IMP)&_logos_method$_ungrouped$WCStoryActionToolBar$initWithFrame$, (IMP*)&_logos_orig$_ungrouped$WCStoryActionToolBar$initWithFrame$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$WCStoryActionToolBar, @selector(onShowAlertViewOfDwn), (IMP)&_logos_method$_ungrouped$WCStoryActionToolBar$onShowAlertViewOfDwn, _typeEncoding); }Class _logos_class$_ungrouped$UIButton = objc_getClass("UIButton"); MSHookMessageEx(_logos_class$_ungrouped$UIButton, @selector(setImage:forState:), (IMP)&_logos_method$_ungrouped$UIButton$setImage$forState$, (IMP*)&_logos_orig$_ungrouped$UIButton$setImage$forState$);} }
#line 182 "/Users/kinken_yuen/Desktop/WeChatMomentVideoDwn1-.0.1/WeChatMomentVideoDwn/WeChatMomentVideoDwn.xm"
