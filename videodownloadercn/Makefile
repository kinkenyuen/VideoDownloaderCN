# THEOS_DEVICE_IP=127.0.0.1
# THEOS_DEVICE_PORT=2222
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VideoDownloaderCN

VideoDownloaderCN_FILES = WeChatMomentVideo.xm WeiboVideo.xm Neteasemusic.xm TwitterVideo.xm YouTubeVideo.xm WeiboInternational.xm Taobao.xm lib/MBProgressHUD/MBProgressHUD.m lib/DownloaderManager/DownloaderManager.m lib/VideoAudioComposition/VideoAudioComposition.m
VideoDownloaderCN_FILES += YYMobile/YM.xm
VideoDownloaderCN_FILES += YYMobile/YMShort.xm
VideoDownloaderCN_FILES += QQ/QQVideo.xm
VideoDownloaderCN_FILES += QQMusic/QQMusic.xm
VideoDownloaderCN_FILES += Toutiao/articleNews.xm

VideoDownloaderCN_CFLAGS = -fobjc-arc
VideoDownloaderCN_OBJCFLAGS += -I./lib/DownloaderManager
VideoDownloaderCN_OBJCFLAGS += -I./lib/MBProgressHUD
VideoDownloaderCN_OBJCFLAGS += -I./lib/VideoAudioComposition

export ARCHS = armv7 armv7s arm64 arm64e
export TARGET = iphone:clang:12.4:8.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	# install.exec "killall -9 SpringBoard"
SUBPROJECTS += videodownloadercnprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
