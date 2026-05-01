// DYYYCompat.h — v38.4.0 兼容层（OpenClaw 版）
// 用途：集中管理 Hook 类名 + 安全查找，版本间一键切换
// v38.4.0 验证结果：所有类名均存在，不改动

#ifndef DYYYCompat_h
#define DYYYCompat_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================
// §1 ObjC 核心类名（稳定）
// ============================================

#define DYYY_CLS_AWEURLModel             @"AWEURLModel"              // 核心：无水印 URL 提取
#define DYYY_CLS_AWEVideoModel           @"AWEVideoModel"            // 视频模型
#define DYYY_CLS_PlayInteractionVC       @"AWEPlayInteractionViewController"
#define DYYY_CLS_PlayVideoVC             @"AWEAwemePlayVideoViewController"
#define DYYY_CLS_FeedRootVC              @"AWEFeedRootViewController"
#define DYYY_CLS_CommentContainerVC      @"AWECommentContainerViewController"
#define DYYY_CLS_UserActionSheetView     @"AWEUserActionSheetView"
#define DYYY_CLS_AppDelegate             @"AppDelegate"
#define DYYY_CLS_VersionUpdateManager    @"AWEVersionUpdateManager"

// ============================================
// §2 Swift 类名（v38.4.0 已确认全部存在）
// ============================================

// 行 2174 — 评论长按复制
#define DYYY_CLS_SWIFT_CommentCopy \
    @"_TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement"

// 行 2699 — 评论贴纸组件
#define DYYY_CLS_SWIFT_CommentSticker \
    @"_TtCV28AWECommentPanelListSwiftImpl6NEWAPI27CommentCellStickerComponent"

// 行 2716 — 评论长按保存图片
#define DYYY_CLS_SWIFT_CommentSaveImage \
    @"_TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement"

// 行 3991 — 直播排行榜入口
#define DYYY_CLS_SWIFT_LiveRankEntrance \
    @"_TtC18IESLiveRevenueImpl34IESLiveDynamicRankListEntranceView"

// 行 4724 — 直播用户进场
#define DYYY_CLS_SWIFT_LiveUserEnter \
    @"_TtC18IESLiveRevenueImpl32IESLiveSwiftDynamicUserEnterView"

// 行 4755 — 直播视频层
#define DYYY_CLS_SWIFT_LiveVideoUserEnter \
    @"_TtC18IESLiveRevenueImpl35IESLiveSwiftVideoLayerUserEnterView"

// 行 8645 — 激励挂件
#define DYYY_CLS_SWIFT_IncentivePendant \
    @"_TtC21AWEIncentiveSwiftImpl29IncentivePendantContainerView"

// 行 8813 — 激励挂件 Lite 版
#define DYYY_CLS_SWIFT_IncentivePendantLite \
    @"AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView"

// ============================================
// §3 安全类查找函数
// ============================================

static inline Class DYYYGetClass(NSString *name) {
    Class cls = objc_getClass(name.UTF8String);
    if (!cls) NSLog(@"[DYYY] ⚠️ Class %@ not found", name);
    return cls;
}

static inline Class DYYYGetClassFromCandidates(NSArray<NSString *> *names) {
    for (NSString *name in names) {
        Class cls = objc_getClass(name.UTF8String);
        if (cls) {
            if (![name isEqualToString:names.firstObject]) {
                NSLog(@"[DYYY] 🔄 %@ → %@", names.firstObject, name);
            }
            return cls;
        }
    }
    NSLog(@"[DYYY] ⚠️ All candidates failed: %@",
          [names componentsJoinedByString:@", "]);
    return nil;
}

#endif
