//
//  DYYYVideoHooks.xm
//  DYYY
//
//  视频相关 Hooks 模块
//  包含：视频下载、播放控制、进度条、画质设置等
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

#pragma mark - 默认视频流最高画质

%hook AWEVideoModel

- (AWEURLModel *)playURL {
    if (!DYYYGetBool(@"DYYYEnableVideoHighestQuality")) {
        return %orig;
    }

    NSArray *bitrateModels = [self bitrateModels];
    if (!bitrateModels || bitrateModels.count == 0) {
        return %orig;
    }

    id highestBitrateModel = nil;
    NSInteger highestBitrate = 0;

    for (id model in bitrateModels) {
        NSInteger bitrate = 0;
        BOOL validModel = NO;

        if ([model isKindOfClass:NSClassFromString(@"AWEVideoBSModel")]) {
            id bitrateValue = [model bitrate];
            if (bitrateValue) {
                bitrate = [bitrateValue integerValue];
                validModel = YES;
            }
        }

        if (validModel && bitrate > highestBitrate) {
            highestBitrate = bitrate;
            highestBitrateModel = model;
        }
    }

    if (highestBitrateModel) {
        id playURL = [highestBitrateModel playURL];
        if (playURL) {
            return playURL;
        }
    }

    return %orig;
}

%end

#pragma mark - 关闭不可见水印

%hook AWEHPChannelInvisibleWaterMarkModel

- (BOOL)isEnter {
    return NO;
}

- (BOOL)isAppear {
    return NO;
}

%end

#pragma mark - 视频播放进度条标签

%hook AWEFeedProgressSlider

- (void)dyyy_updateScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    %orig;

    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        [self dyyy_removeScheduleLabels];
        return;
    }

    [self dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
}

%end

%hook AWEPlayInteractionProgressController

- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    %orig;

    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        return;
    }

    [self dyyy_syncScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
}

%end

%hook AWEDProgressCoreContainer

- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    %orig;

    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        return;
    }

    [self dyyy_syncScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
}

%end

%hook AWEPlayInteractionTimestampElement

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYShowTimestampDisplay")) {
        return;
    }

    [self setNeedsLayout];
}

%end

#pragma mark - 视频按钮 Hook

%hook AWEFeedVideoButton

- (void)setLike:(BOOL)arg1 {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyLikeButton")) {
        return;
    }

    [self setNeedsLayout];
}

%end

#pragma mark - 自动播放管理

%hook AWEFeedIPhoneAutoPlayManager

- (void)startAutoPlay {
    if (DYYYGetBool(@"DYYYDisableAutoPlay")) {
        NSLog(@"[DYYY] AutoPlay blocked");
        return;
    }
    %orig;
}

- (void)stopAutoPlay {
    %orig;
}

%end

%hook AWEFeedModuleService

- (void)startAutoPlayIfNeeded {
    if (DYYYGetBool(@"DYYYDisableAutoPlay")) {
        NSLog(@"[DYYY] FeedModuleService AutoPlay blocked");
        return;
    }
    %orig;
}

%end

#pragma mark - 视频分享链接解析

%hook AWEURLModel

- (NSString *)getDYYYSrcURL {
    NSString *original = %orig;
    if (!original || original.length == 0) {
        return original;
    }

    if (DYYYGetBool(@"DYYYEnableCustomAPI")) {
        return original;
    }

    return original;
}

%end

%hook AWEPlayInteractionUserAvatarElement

- (void)handleTapGesture:(id)arg1 {
    if (DYYYGetBool(@"DYYYDisableAvatarClick")) {
        return;
    }
    %orig;
}

%end

%hook AWEPlayInteractionUserAvatarFollowController

- (void)followButtonClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYDisableFollowButton")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 视频速度控制

%hook AWEPlayInteractionSpeedController

- (void)setSpeed:(float)arg1 {
    float customSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
    if (customSpeed > 0.0f) {
        %orig(customSpeed);
    } else {
        %orig;
    }
}

%end

#pragma mark - 描述标签

%hook AWEPlayInteractionDescriptionLabel

- (void)setText:(id)arg1 {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyDescription")) {
        return;
    }
}

%end

%hook AWEPlayInteractionDescriptionScrollView

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYExpandDescription")) {
        return;
    }
}

%end

#pragma mark - 用户名标签

%hook AWEUserNameLabel

- (void)setNickname:(id)arg1 {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyNickname")) {
        return;
    }
}

%end

#pragma mark - 进度容器视图

%hook AWEPlayInteractionProgressContainerView

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyProgressContainer")) {
        return;
    }
}

%end

#pragma mark - 顶栏标签

%hook AWEFeedTopBarContainer

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyTopBar")) {
        return;
    }
}

%end

%hook AWEHPTopTabItemTextContentView

- (void)setTitleText:(id)arg1 {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyTopTabText")) {
        return;
    }
}

%end

#pragma mark - 频道管理器

%hook AWERLVirtualLabel

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyVirtualLabel")) {
        return;
    }
}

%end

%hook AWEDateTimeFormatter

- (NSString *)formatDate:(id)arg1 {
    NSString *result = %orig;
    return result;
}

%end

#pragma mark - 横屏控制器

%hook AWELandscapeFeedViewController

- (void)viewDidLoad {
    %orig;

    if (DYYYGetBool(@"DYYYModifyLandscape")) {
        NSLog(@"[DYYY] Landscape controller loaded");
    }
}

%end

#pragma mark - 弹幕视图

%hook AWEDanmakuContentLabel

- (void)setText:(id)arg1 {
    %orig;

    if (!DYYYGetBool(@"DYYYShowDanmaku")) {
        return;
    }
}

%end

%hook XIGDanmakuPlayerView

- (void)startDanmaku {
    if (DYYYGetBool(@"DYYYDisableDanmaku")) {
        return;
    }
    %orig;
}

%end

%hook DDanmakuPlayerView

- (void)start {
    if (DYYYGetBool(@"DYYYDisableDanmaku")) {
        return;
    }
    %orig;
}

%end

%hook AWEPlayDanmakuInputContainView

- (void)showInputView {
    if (DYYYGetBool(@"DYYYHideDanmakuInput")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 标记视图

%hook AWEMarkView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideMarkView")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

%hook LOTAnimationView

- (void)startAnimating {
    if (DYYYGetBool(@"DYYYDisableAnimation")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 广告头像

%hook AWEAdAvatarView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideAdAvatar")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 附近天空胶囊

%hook AWENearbySkyLightCapsuleView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideNearbySkyLight")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 搜索气泡入口

%hook AWEHPSearchBubbleEntranceView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideSearchBubble")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 直播标签

%hook AWEFeedLiveMarkView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideLiveMark")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

%hook AWEFeedLiveTabTopSelectionView

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyLiveTabSelection")) {
        return;
    }
}

%end

#pragma mark - 音乐封面按钮

%hook AWEMusicCoverButton

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyMusicCover")) {
        return;
    }
}

%end

#pragma mark - POI 入口

%hook AWEPOIEntryAnchorView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHidePOIEntry")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 取消静音视图

%hook AFDCancelMuteAwemeView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideCancelMute")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 直播指南元素

%hook AWELiveGuideElement

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideLiveGuide")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

%hook AWEShowPlayletCommentHeaderView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHidePlayletCommentHeader")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

%hook AWECommentGuideLunaAnchorView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideCommentGuideLuna")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end
