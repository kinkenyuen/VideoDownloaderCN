
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VideoDownloaderCN
VideoDownloaderCN_FILES = WeChatMomentVideo.xm WeiboVideo.xm Neteasemusic.xm lib/UAProgressView/UAProgressView.m

VideoDownloaderCN_CFLAGS = -fobjc-arc

export ARCHS = armv7 armv7s arm64
export TARGET = iphone:clang:11.2:8.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += videodownloadercnprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
