#pragma mark - 微博

#import <UIKit/UIKit.h>
#import "lib/DownloaderManager/DownloaderManager.h"

@interface WBVideoItem : NSObject
@property(readonly, copy, nonatomic) NSURL *urlHD;
@end

@interface WBStatus : NSObject
@property(readonly, nonatomic) WBVideoItem *vt_videoItem;
@property(readonly, nonatomic) id retweetByStatus;
@property(readonly, nonatomic) id pageInfo;
@end

@interface WBPageCardStatus : WBStatus
@end

@interface WBVideoTimelineTableViewCell : NSObject
@property(retain, nonatomic) WBStatus *status;
@end

@interface WBVideoTimelineViewController
@property(readonly, nonatomic) WBVideoTimelineTableViewCell *playingCell;
@end

@interface WBVideoContainerView : UIView <UIAlertViewDelegate, NSURLSessionDelegate>
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;

- (void)downloadVideoWithURL:(NSURL *)url;
@end

@interface WBTimelinePageInfo : NSObject
@property(readonly, nonatomic) id videoItem;
@end

@interface WBVideoModel : WBVideoItem
@end

%hook WBVideoContainerView

- (void)setFrame:(struct CGRect)arg1 {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self addGestureRecognizer:longPress];
    %orig;
}

%new
- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    //解决手势触发两次
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"下载该视频?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        [alert show];
    }
}

%new;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSURL *url = nil;
        //self == WBVideoContainerView
        /**
         第一种情况，点开视频长按下载
         */
        id wbTimeLineVC = [[[[[[[self nextResponder]nextResponder]nextResponder]nextResponder]nextResponder]nextResponder]nextResponder];
        if ([wbTimeLineVC isKindOfClass:%c(WBVideoTimelineViewController)]) {
            //取出当前视频的cell
            WBVideoTimelineTableViewCell *playingCell = [wbTimeLineVC playingCell];
            if ([playingCell isKindOfClass:%c(WBVideoTimelineTableViewCell)]) {
                //每个WBstatus记录着视频的信息
                WBStatus *status = [playingCell status];
                if ([status isKindOfClass:%c(WBPageCardStatus)]) {
                    //检查是否转发的视频
                    WBTimelinePageInfo *pageInfo = nil;
                    WBPageCardStatus *retweetByStatus = [status retweetByStatus];
                    if ([retweetByStatus isKindOfClass:%c(WBPageCardStatus)]) {
                        pageInfo = [retweetByStatus pageInfo];
                    }else {
                        pageInfo = [status pageInfo];
                    }
                    if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
                        WBVideoModel *videoItem = [pageInfo videoItem];
                        if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                            url = [videoItem urlHD];
                        }
                    }
                } else if ([status isKindOfClass:%c(WBStatus)]) {
                    WBVideoItem *vt_videoItem = [status vt_videoItem];
                    if ([vt_videoItem isKindOfClass:%c(WBVideoItem)]) {
                        url = [vt_videoItem urlHD];
                    }
                }
            }
        }
        
        /**
         第二种情况，未点开视频，长按下载
         */
        //2.1转发情况
        id wbTimelineLargeCardViewRetweet = [[[self nextResponder]nextResponder]nextResponder];
        //2.2非转发情况
        id wbTimelineLargeCardViewSelf = [[self nextResponder]nextResponder];
        
        id wbTimelineLargeCardView = nil;
        if ([wbTimelineLargeCardViewRetweet isKindOfClass:%c(WBTimelineLargeCardView)]) {
            wbTimelineLargeCardView = wbTimelineLargeCardViewRetweet;
        }else if ([wbTimelineLargeCardViewSelf isKindOfClass:%c(WBTimelineLargeCardView)]) {
            wbTimelineLargeCardView = wbTimelineLargeCardViewSelf;
        }

        if (wbTimelineLargeCardView) {
            WBTimelinePageInfo *pageInfo = [wbTimelineLargeCardView pageInfo];
            if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
                WBVideoModel *videoItem = [pageInfo videoItem];
                if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                    url = [videoItem urlHD];
                }
            }
        }
        
        /**
         第三种情况，视屏全屏播放界面
         */
        id wbVideoPlayerViewController = [[self nextResponder]nextResponder];
        if ([wbVideoPlayerViewController isKindOfClass:%c(WBVideoPlayerViewController)]) {
            WBVideoItem *videoItem = [wbVideoPlayerViewController videoItem];
            if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                url = [videoItem urlHD];
            }
        }
        
        /**
         第四种情况，首页"视频"标签入口
         */
        id wbPageVideoPlaylistCardLargeVideoView = [self nextResponder];
        if ([wbPageVideoPlaylistCardLargeVideoView isKindOfClass:%c(WBPageVideoPlaylistCardLargeVideoView)]) {
            WBTimelinePageInfo *pageInfo = [wbPageVideoPlaylistCardLargeVideoView pageInfo];
            if ([pageInfo isKindOfClass:%c(WBTimelinePageInfo)]) {
                WBVideoModel *videoItem = [pageInfo videoItem];
                if ([videoItem isKindOfClass:%c(WBVideoItem)]) {
                    url = [videoItem urlHD];
                }
            }
        }
        
        id wbVideoSocialPlayerViewController = [[[self nextResponder] nextResponder] nextResponder];
        if ([wbVideoSocialPlayerViewController isKindOfClass:%c(WBVideoSocialPlayerViewController)]) {
            WBVideoItem *_currentVideoItem = MSHookIvar<WBVideoItem *>(wbVideoSocialPlayerViewController, "_currentVideoItem");
            if ([_currentVideoItem isKindOfClass:%c(WBVideoItem)]) {
                url = [_currentVideoItem urlHD];
            }
        }
        
        /**
         拿到视频url下载
         */
        if (url)
        {
            DownloaderManager *downloadManager = [DownloaderManager sharedDownloaderManager];
            [downloadManager setProgressViewWindow:self];
            [downloadManager downloadVideoWithURL:url];
        }
    }
}

%end

/**
 插件开关
 */
static BOOL weiboEnable = NO;

static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.kinkenyuen.videodownloadercnprefs.plist"];
    weiboEnable = [settings objectForKey:@"weiboEnable"] ? [[settings objectForKey:@"weiboEnable"] boolValue] : NO;
}

%ctor {
    loadPrefs();
    if (weiboEnable)
    {
        %init(_ungrouped);
    }
    
}
