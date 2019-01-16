include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = videodownloadercnprefs
videodownloadercnprefs_FILES = KenRootListController.m
videodownloadercnprefs_INSTALL_PATH = /Library/PreferenceBundles
videodownloadercnprefs_FRAMEWORKS = UIKit
videodownloadercnprefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/videodownloadercnprefs.plist$(ECHO_END)
