//
//  DYYYUIHooks.xm
//  DYYY
//
//  界面相关 Hooks 模块
//  包含：侧边栏、导航栏、搜索、分享、通知、模板等
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

#pragma mark - 个人简介复制

%hook AWEProfileMentionLabel

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYBioCopyText")) {
        return;
    }

    BOOL hasLongPressGesture = NO;
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
            hasLongPressGesture = YES;
            break;
        }
    }

    if (!hasLongPressGesture) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressGesture.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPressGesture];
        self.userInteractionEnabled = YES;
    }
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSString *bioText = self.text;
        if (bioText && bioText.length > 0) {
            [[UIPasteboard generalPasteboard] setString:bioText];
            [DYYYToast showSuccessToastWithMessage:@"个人简介已复制"];
        }
    }
}

%end

#pragma mark - 自动勾选原图

%hook AWEIMPhotoPickerFunctionModel

- (void)setUseShadowIcon:(BOOL)arg1 {
    BOOL enabled = DYYYGetBool(@"DYYYAutoSelectOriginalPhoto");
    if (enabled) {
        %orig(YES);
    } else {
        %orig(arg1);
    }
}

- (BOOL)isSelected {
    BOOL enabled = DYYYGetBool(@"DYYYAutoSelectOriginalPhoto");
    if (enabled) {
        return YES;
    }
    return %orig;
}

%end

%hook AFDProfileAvatarFunctionManager

- (void)setupAvatarFunction {
    %orig;
}

%end

#pragma mark - 搜索锚点列表模型

%hook AWESearchAnchorListModel

- (BOOL)hideWords {
    return DYYYGetBool(@"DYYYHideCommentViews");
}

%end

#pragma mark - 隐藏观看历史搜索

%hook AWEDiscoverFeedEntranceView

- (id)init {
    if (DYYYGetBool(@"DYYYHideInteractionSearch")) {
        return nil;
    }
    return %orig;
}

%end

#pragma mark - 隐藏校园提示

%hook AWETemplateTagsCommonView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideTemplateTags")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end

#pragma mark - 隐藏消息页顶栏头像气泡

%hook AFDSkylightCellBubble

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideAvatarBubble")) {
        [self removeFromSuperview];
    }
    %orig;
}

%end

#pragma mark - 隐藏消息页开启通知提示

%hook AWEIMMessageTabOptPushBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYHidePushBanner")) {
        return %orig(CGRectMake(frame.origin.x, frame.origin.y, 0, 0));
    }
    return %orig;
}

%end

#pragma mark - 隐藏消息页顶栏红包

%hook AWEIMMessageTabSideBarView

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMessageTabRedPacket")) {
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }

    NSArray<UIView *> *siblings = [parentView.subviews copy];
    if (siblings.count <= 1) {
        return;
    }

    for (UIView *subview in siblings) {
        if (subview != self) {
            [subview removeFromSuperview];
        }
    }
}

%end

#pragma mark - 隐藏我的添加朋友

%hook AWEProfileNavigationButton

- (void)setupUI {

    if (DYYYGetBool(@"DYYYHideButton")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 隐藏朋友"关注/不关注"按钮

%hook AWEFeedUnfollowFamiliarFollowAndDislikeView

- (void)showUnfollowFamiliarView {
    if (DYYYGetBool(@"DYYYHideFamiliar")) {
        self.hidden = YES;
        return;
    }
    %orig;
}

%end

#pragma mark - 隐藏朋友日常按钮

%hook AWEFamiliarNavView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideFamiliar")) {
        self.hidden = YES;
    }
    %orig;
}

%end

#pragma mark - 隐藏分享给朋友提示

%hook AWEPlayInteractionStrongifyShareContentView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideShareContentView")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end

#pragma mark - 左侧边栏入口

%hook AWELeftSideBarEntranceView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideLeftSideBarEntrance")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

%hook AWELeftSideBarAddChildTransitionObject

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideLeftSideBarEntrance")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 频道管理器

%hook AWEFeedChannelManager

- (void)setCurrentChannel:(id)arg1 {
    %orig;
}

%end

#pragma mark - 标签跳转指南

%hook AWEFeedTabJumpGuideView

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideTabJumpGuide")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - YYLabel Hook

%hook YYLabel

- (void)setText:(id)arg1 {
    %orig;
}

%end

#pragma mark - UILabel Hook

%hook UILabel

- (void)setText:(id)arg1 {
    %orig;
}

%end

#pragma mark - UIWindow Hook

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
}

%end

#pragma mark - UIButton Hook

%hook UIButton

- (void)setEnabled:(BOOL)arg1 {
    %orig;
}

%end

#pragma mark - 基础列表视图控制器

%hook AWEBaseListViewController

- (void)viewDidLoad {
    %orig;
}

%end

#pragma mark - 普通模式标签栏加号按钮

%hook AWENormalModeTabBarGeneralPlusButton

- (void)setHidden:(BOOL)arg1 {
    if (DYYYGetBool(@"DYYYHideTabBarPlusButton")) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark - 版本更新管理器

%hook AWEVersionUpdateManager

- (void)checkForUpdates {
    if (DYYYGetBool(@"DYYYDisableVersionUpdate")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 快速回复视图控制器

%hook AWEIMFeedVideoQuickReplayInputViewController

- (void)viewDidLoad {
    %orig;
}

%end

#pragma mark - 列表视图

%hook UICollectionView

- (void)reloadData {
    %orig;
}

%end
