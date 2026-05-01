//
//  DYYLiveHooks.xm
//  DYYY
//
//  直播相关 Hooks 模块
//  包含：直播画质、PCDN、投屏、直播指南等
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <float.h>
#import <math.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"
#import "DYYYConstants.h"

#pragma mark - 屏蔽直播 PCDN

%hook HTSLiveStreamPcdnManager

+ (void)start {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (!disablePCDN) {
        %orig;
    } else {
        NSLog(@"[DYYY] HTSLiveStreamPcdnManager start blocked");
    }
}

+ (void)configAndStartLiveIO {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (!disablePCDN) {
        %orig;
    } else {
        NSLog(@"[DYYY] HTSLiveStreamPcdnManager configAndStartLiveIO blocked");
    }
}

%end

%hook IESLiveLaunchTaskPcdn

- (void)excute {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (disablePCDN) {
        NSLog(@"[DYYY] IESLiveLaunchTaskPcdn excute blocked");
        return;
    }
    %orig;
}

%end

%hook IESLiveUserSeqlistFragment

- (void)loadData {
    %orig;
}

%end

#pragma mark - 投屏忽略 VPN 检测

%hook BDByteCastUtils

+ (BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

%end

%hook BDByteCastNetUtilities

- (BOOL)getVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

%end

%hook BDByteCastMonitorManager

- (BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setNetVPNStatus:(BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(netVPNStatus);
}

%end

%hook BDByteCastEnvInfo

- (BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setIsVPNActive:(BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(isVPNActive);
}

%end

%hook BDByteScreenCastContext

- (BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setIsVPNActive:(BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(isVPNActive);
}

%end

#pragma mark - 调整直播默认清晰度功能

static NSArray<NSString *> *dyyy_qualityRank = nil;

%hook HTSLiveStreamQualityFragment

- (void)setupStreamQuality:(id)arg1 {
    %orig;

    NSString *preferredQuality = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLiveQuality"];
    if (!preferredQuality || [preferredQuality isEqualToString:@"自动"]) {
        NSLog(@"[DYYY] Live quality auto - skipping hook");
        return;
    }

    BOOL preferLower = YES;
    NSLog(@"[DYYY] preferredQuality=%@ preferLower=%@", preferredQuality, @(preferLower));

    NSArray *qualities = self.streamQualityArray;
    if (!qualities || qualities.count == 0) {
        qualities = [self getQualities];
    }
    if (!qualities || qualities.count == 0) {
        return;
    }

    if (!dyyy_qualityRank) {
        dyyy_qualityRank = @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清" ];
    }
    NSArray *orderedNames = dyyy_qualityRank;

    NSInteger currentIndex = [orderedNames indexOfObject:preferredQuality];
    if (currentIndex == NSNotFound) {
        return;
    }

    NSInteger targetIndex = preferLower ? currentIndex : currentIndex;
    if (targetIndex < 0 || targetIndex >= qualities.count) {
        return;
    }

    id targetQuality = qualities[targetIndex];
    if (targetQuality) {
        [self setSelectedIndex:targetIndex];
        NSLog(@"[DYYY] Set live quality to: %@", preferredQuality);
    }
}

%end

#pragma mark - 长按面板数据管理器

%hook AWELongPressPanelDataManager

- (void)setupPanelWithData:(id)arg1 {
    %orig;
}

%end

%hook AWELongPressPanelABSettings

- (void)setupABSettings:(id)arg1 {
    %orig;
}

%end

%hook AWEModernLongPressPanelUIConfig

- (void)setupUIConfig:(id)arg1 {
    %orig;
}

%end

#pragma mark - 用户标签列表模型

%hook AWEUserTabListModel

- (void)loadTabList {
    %orig;
}

%end

#pragma mark - 详情页面控制器

%hook AWEAwemeDetailTableViewController

- (void)viewDidLoad {
    %orig;
}

%end

%hook AWEAwemeDetailContainerPlayControlConfig

- (void)setupPlayControlConfig {
    %orig;
}

%end

#pragma mark - 内部通知窗口

%hook AWEInnerNotificationWindow

- (void)showNotification:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideInnerNotification")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 用户操作表视图

%hook AWEUserActionSheetView

- (void)showActionSheet {
    if (DYYYGetBool(@"DYYYHideUserActionSheet")) {
        return;
    }
    %orig;
}

%end
