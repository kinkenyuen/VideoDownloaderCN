include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VideoDownloaderCN
VideoDownloaderCN_FILES = WeChatMomentVideo.xm WeiboVideo.xm Neteasemusic.xm

VideoDownloaderCN_CFLAGS = -fobjc-arc

export TARGET = iphone:clang:11.2:8.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += videodownloadercnprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
