# THEOS_DEVICE_IP=127.0.0.1
# THEOS_DEVICE_PORT=2222
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VideoDownloaderCN

$(TWEAK_NAME)_FILES = lib/MBProgressHUD/MBProgressHUD.m lib/DownloaderManager/DownloaderManager.m lib/VideoAudioComposition/VideoAudioComposition.m
# VideoDownloaderCN_FILES += YYMobile/YM.xm
# VideoDownloaderCN_FILES += YYMobile/YMShort.xm
$(TWEAK_NAME)_FILES += lib/DownloaderManager/KKFileMultiDownloadUnit.m
$(TWEAK_NAME)_FILES += lib/DownloaderManager/KKFileMultiDownloadCenter.m
$(TWEAK_NAME)_FILES += QQ/QQVideo.xm
# $(TWEAK_NAME)_FILES += QQMusic/QQMusic.xm
$(TWEAK_NAME)_FILES += Toutiao/articleNews.xm
$(TWEAK_NAME)_FILES += NeteaseMusic/Neteasemusic.xm
# $(TWEAK_NAME)_FILES += Weibo/WeiboInternational.xm
$(TWEAK_NAME)_FILES += Weibo/WeiboVideo.xm
$(TWEAK_NAME)_FILES += Twitter/TwitterVideo.xm
$(TWEAK_NAME)_FILES += Taobao/Taobao.xm
# $(TWEAK_NAME)_FILES += WeChat/WeChatMomentVideo.xm
$(TWEAK_NAME)_FILES += Taobao/Taobao.xm
$(TWEAK_NAME)_FILES += Youtube/YouTubeVideo.xm


$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_OBJCFLAGS += -I./lib/DownloaderManager
$(TWEAK_NAME)_OBJCFLAGS += -I./lib/MBProgressHUD
$(TWEAK_NAME)_OBJCFLAGS += -I./lib/VideoAudioComposition

export ARCHS = armv7 armv7s arm64 arm64e
export TARGET = iphone:clang:13.7:8.0

$(TWEAK_NAME)_CCFLAGS += -std=c++14 -stdlib=libc++	

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	# install.exec "killall -9 SpringBoard"
SUBPROJECTS += videodownloadercnprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
