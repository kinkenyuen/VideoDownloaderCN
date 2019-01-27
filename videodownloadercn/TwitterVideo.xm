#pragma mark - Twitter

#import <UIKit/UIKit.h>
#import "lib/DownloaderManager/DownloaderManager.h"

@interface TAVPlayerView
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (UIWindow *)lastWindow;
@end

@interface T1SlideshowSlide
@end

@interface TFSTwitterEntityMedia
@end

@interface TFSTwitterEntityMediaVideoInfo
@property(readonly, copy, nonatomic) NSString *primaryUrl;
@end

@interface TFSTwitterEntityMediaVideoVariant : NSObject
@property(readonly, copy, nonatomic) NSString *url; 
@end


%hook TAVPlayerView

- (id)initWithFrame:(struct CGRect)arg1 {
	id selfView = %orig;
    if ([selfView isKindOfClass:%c(TAVPlayerView)]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [selfView addGestureRecognizer:longPress];
    }
    return selfView;
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"下载该视频?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        [alert show];
    }
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ( buttonIndex == 1)
	{
		NSURL *url = nil;
		id targetVC = [[[[self nextResponder] nextResponder] nextResponder] nextResponder];
		if ([targetVC isKindOfClass:%c(T1SlideshowViewController)]) {
			T1SlideshowSlide *currentSlide = MSHookIvar<T1SlideshowSlide *>(targetVC, "_currentSlide");
			TFSTwitterEntityMedia *media = MSHookIvar<TFSTwitterEntityMedia *>(currentSlide, "_media");
			TFSTwitterEntityMediaVideoInfo *videoInfo = MSHookIvar<TFSTwitterEntityMediaVideoInfo *>(media,"_videoInfo");
			NSString *primaryUrl = [videoInfo primaryUrl];
			if (primaryUrl && [primaryUrl containsString:@"mp4"])
			{
				url = [NSURL URLWithString:primaryUrl];
			}

			NSArray *variants = MSHookIvar<NSArray *>(videoInfo,"_variants");
			for (int i = 0;i < variants.count;i++) {
				TFSTwitterEntityMediaVideoVariant *variant = variants[i];
				if ([variant isKindOfClass:%c(TFSTwitterEntityMediaVideoVariant)])
				{
					NSString *urlString = [variant url];
					if ( urlString && [urlString containsString:@"mp4"])
					{	
						url = [NSURL URLWithString:urlString];
						break;
					}
				}
			}
		}
		if (url)
		{
			DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
			[downloadManager setProgressViewWindow:[self lastWindow]];
			[downloadManager downloadVideoWithURL:url];
		}
	}
}

%new
- (UIWindow *)lastWindow {
    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in [windows reverseObjectEnumerator]) {
        if ([window isKindOfClass:[UIWindow class]] && CGRectEqualToRect(window.bounds, [UIScreen mainScreen].bounds)) {
            return window;
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

%end

/**
 插件开关
 */
static BOOL twitterEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    twitterEnable = [settings objectForKey:@"twitterEnable"] ? [[settings objectForKey:@"twitterEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (twitterEnable)
    {
        %init(_ungrouped);
    }
    
}