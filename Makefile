#
#  DYYY Makefile
#  模块化版本 v2.0
#

TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

# 打包方案选择
ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
else
    unexport THEOS_PACKAGE_SCHEME
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

# ========================================
# 源文件列表
# ========================================

# 主入口
DYYY_FILES = DYYY.xm

# Swift Hook 安全模式
DYYY_FILES += DYYYSwiftHookManager.m
DYYY_FILES += DYYYSwiftHooksSafe.m

# 模块化 Hooks
DYYY_FILES += DYYYVideoHooks.xm
DYYY_FILES += DYYYCommentHooks.xm
DYYY_FILES += DYYYLiveHooks.xm
DYYY_FILES += DYYYUIHooks.xm

# UI 组件
DYYY_FILES += DYYYFloatClearButton.xm
DYYY_FILES += DYYYFloatSpeedButton.m
DYYY_FILES += DYYYSettings.xm
DYYY_FILES += DYYYABTestHook.xm
DYYY_FILES += DYYYLongPressPanel.xm
DYYY_FILES += DYYYSettingsHelper.m
DYYY_FILES += DYYYImagePickerDelegate.m
DYYY_FILES += DYYYBackupPickerDelegate.m
DYYY_FILES += DYYYSettingViewController.m
DYYY_FILES += DYYYBottomAlertView.m
DYYY_FILES += DYYYCustomInputView.m
DYYY_FILES += DYYYOptionsSelectionView.m
DYYY_FILES += DYYYIconOptionsDialogView.m
DYYY_FILES += DYYYAboutDialogView.m
DYYY_FILES += DYYYKeywordListView.m
DYYY_FILES += DYYYFilterSettingsView.m
DYYY_FILES += DYYYConfirmCloseView.m

# 核心功能
DYYY_FILES += DYYYToast.m
DYYY_FILES += DYYYManager.m
DYYY_FILES += DYYYUtils.m
DYYY_FILES += CityManager.m
DYYY_FILES += AWMSafeDispatchTimer.m

# ========================================
# 编译选项
# ========================================

DYYY_CFLAGS = -fobjc-arc -w -Wno-deprecated-declarations
DYYY_LDFLAGS = -weak_framework AVFAudio -weak_framework Photos
DYYY_FRAMEWORKS = CoreAudio CoreGraphics UIKit Foundation

DYYY_LOGOS_DEFAULT_GENERATOR = internal

include $(THEOS_MAKE_PATH)/tweak.mk

# ========================================
# 构建提示
# ========================================

before-package::
	@echo "========================================"
	@echo "构建 DYYY v2.0 模块化版本"
	@echo "========================================"

after-package::
	@echo "========================================"
	@echo "构建完成!"
	@echo "========================================"
	@ls -lh packages/*.deb 2>/dev/null || echo "检查 packages 目录"

.PHONY: clean-all
clean-all::
	@rm -rf .theos packages
	@echo "清理完成"
