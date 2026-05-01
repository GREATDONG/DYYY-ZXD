//
//  DYYYSwiftHooksSafe.m
//  DYYY
//
//  Swift Hook 安全模式实现
//  针对 7 个 Swift Hook 的零崩溃降级方案
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import "DYYYSwiftHookManager.h"
#import "DYYYCompat.h"
#import "DYYYToast.h"
#import "DYYYManager.h"

@interface DYYYSwiftHooksSafe : NSObject
+ (void)setupAllSwiftHooks;
+ (void)setupCommentCopyHook;
+ (void)setupCommentStickerHook;
+ (void)setupCommentSaveImageHook;
+ (void)setupCommentHeaderGeneralHook;
+ (void)setupCommentHeaderGoodsHook;
+ (void)setupCommentHeaderTemplateHook;
+ (void)setupCommentBottomTipsHook;
@end

@implementation DYYYSwiftHooksSafe

+ (void)setupAllSwiftHooks {
    NSLog(@"[DYYY] SAFE MODE: Setting up all Swift Hooks...");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupCommentCopyHook];
        [self setupCommentStickerHook];
        [self setupCommentSaveImageHook];
        [self setupCommentHeaderGeneralHook];
        [self setupCommentHeaderGoodsHook];
        [self setupCommentHeaderTemplateHook];
        [self setupCommentBottomTipsHook];

        [[DYYYSwiftHookManager sharedManager] logStatus];
    });
}

+ (void)setupCommentCopyHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentCopy hook...");

    Class targetClass = DYYYGetClass(DYYY_CLS_SWIFT_CommentCopy);
    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentCopy class not found, trying candidates...");
        targetClass = DYYYGetClassFromCandidates(@[
            @"_TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement",
            @"_TtC34AWECommentLongPressPanelSwiftImpl232CommentLongPressPanelCopyElement"
        ]);
    }

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentCopy class not found after trying all candidates");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentCopy"];
        return;
    }

    SEL selector = @selector(elementTapped);
    if (!class_respondsToSelector(targetClass, selector)) {
        NSLog(@"[DYYY] SAFE MODE: CommentCopy.elementTapped not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentCopy"];
        return;
    }

    [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                     selector:selector
                                                  replacement:^(id self) {
        if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentCopy"]) {
            return;
        }

        if (!DYYYGetBool(@"DYYYCommentCopyText")) {
            return;
        }

        @try {
            AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
            AWECommentModel *selectdComment = [commentPageContext selectdComment];
            if (!selectdComment) {
                AWECommentLongPressPanelParam *params = [commentPageContext params];
                selectdComment = [params selectdComment];
            }
            NSString *descText = [selectdComment content];
            [[UIPasteboard generalPasteboard] setString:descText];
            [DYYYToast showSuccessToastWithMessage:@"评论已复制"];
        } @catch (NSException *exception) {
            NSLog(@"[DYYY] SAFE MODE: CommentCopy exception: %@", exception.reason);
        }
    } featureName:@"CommentCopy"];
}

+ (void)setupCommentStickerHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentSticker hook...");

    Class targetClass = DYYYGetClassFromCandidates(@[
        @"_TtCV28AWECommentPanelListSwiftImpl6NEWAPI27CommentCellStickerComponent",
        @"_TtCV29AWECommentPanelListSwiftImpl27CommentCellStickerComponent"
    ]);

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentSticker class not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentSticker"];
        return;
    }

    SEL selector = @selector(handleLongPressWithGes:);
    if (!class_respondsToSelector(targetClass, selector)) {
        selector = NSSelectorFromString(@"handleLongPressWithGes:");
        if (!class_respondsToSelector(targetClass, selector)) {
            NSLog(@"[DYYY] SAFE MODE: CommentSticker selector not found");
            [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentSticker"];
            return;
        }
    }

    static __weak YYAnimatedImageView *targetStickerView = nil;
    static BOOL dyyyShouldUseLastStickerURL = NO;

    [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                     selector:selector
                                                  replacement:^(id self, UILongPressGestureRecognizer *gesture) {
        if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentSticker"]) {
            return;
        }

        if (gesture.state == UIGestureRecognizerStateBegan) {
            if ([gesture.view isKindOfClass:NSClassFromString(@"YYAnimatedImageView")]) {
                targetStickerView = (YYAnimatedImageView *)gesture.view;
                NSLog(@"DYYY 长按表情：%@", targetStickerView);
            } else {
                targetStickerView = nil;
            }
        }
    } featureName:@"CommentSticker"];
}

+ (void)setupCommentSaveImageHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentSaveImage hook...");

    Class targetClass = DYYYGetClassFromCandidates(@[
        @"_TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement",
        @"_TtC34AWECommentLongPressPanelSwiftImpl237CommentLongPressPanelSaveImageElement"
    ]);

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentSaveImage class not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentSaveImage"];
        return;
    }

    SEL selector = @selector(elementShouldShow);
    SEL selectorTapped = @selector(elementTapped);

    if (class_respondsToSelector(targetClass, selector)) {
        [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                         selector:selector
                                                      replacement:^BOOL(id self) {
            if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentSaveImage"]) {
                return NO;
            }

            @try {
                BOOL shouldShow = YES;
                if (!DYYYGetBool(@"DYYYForceDownloadEmotion") && !DYYYGetBool(@"DYYYForceDownloadCommentAudio")) {
                    return shouldShow;
                }
                AWECommentLongPressPanelContext *context = [self commentPageContext];
                AWECommentModel *selected = [context selectdComment] ?: [[context params] selectdComment];
                AWEIMStickerModel *sticker = [selected sticker];
                NSArray *originURLList = sticker.staticURLModel.originURLList;
                if (originURLList.count > 0) {
                    return YES;
                }
                AWECommentAudioModel *audio = [selected audioModel];
                if (audio && audio.content) {
                    return YES;
                }
                return shouldShow;
            } @catch (NSException *exception) {
                NSLog(@"[DYYY] SAFE MODE: CommentSaveImage.elementShouldShow exception: %@", exception.reason);
                return NO;
            }
        } featureName:@"CommentSaveImage_elementShouldShow"];
    }

    if (class_respondsToSelector(targetClass, selectorTapped)) {
        [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                         selector:selectorTapped
                                                      replacement:^(id self) {
            if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentSaveImage"]) {
                return;
            }

            @try {
                AWECommentLongPressPanelContext *context = [self commentPageContext];
                AWECommentLongPressPanelParam *params = [context params];
                AWECommentModel *comment = [context selectdComment] ?: [params selectdComment];

                AWEIMStickerModel *sticker = [comment sticker];
                NSArray *stickerURLList = sticker.staticURLModel.originURLList;
                BOOL hasSticker = (stickerURLList.count > 0);

                AWECommentAudioModel *audio = [comment audioModel];
                BOOL hasAudio = (audio && audio.content);

                NSArray *imageList = nil;
                if ([comment respondsToSelector:@selector(imageList)]) {
                    imageList = [comment imageList];
                }
                BOOL hasImages = (imageList && imageList.count > 0);

                if (hasSticker && DYYYGetBool(@"DYYYForceDownloadEmotion")) {
                    NSString *urlString = dyyyShouldUseLastStickerURL ? stickerURLList.lastObject : stickerURLList.firstObject;
                    dyyyShouldUseLastStickerURL = NO;
                    NSURL *stickerURL = [NSURL URLWithString:urlString];

                    if (stickerURL) {
                        [DYYYManager downloadMedia:stickerURL
                                         mediaType:MediaTypeHeic
                                             audio:nil
                                        completion:^(BOOL success) {
                            if (!success && stickerURLList.count > 1) {
                                dyyyShouldUseLastStickerURL = YES;
                            }
                        }];
                        return;
                    }
                }

                if (hasAudio && DYYYGetBool(@"DYYYForceDownloadCommentAudio")) {
                    NSString *audioContent = audio.content;
                    NSString *userName = @"未知用户";
                    if (comment.author && [comment.author respondsToSelector:@selector(nickname)]) {
                        NSString *nickname = [comment.author performSelector:@selector(nickname)];
                        if (nickname && nickname.length > 0) {
                            userName = nickname;
                        }
                    }
                    [DYYYManager downloadAndShareCommentAudio:audioContent
                                                     userName:userName
                                                   createTime:comment.createTime];
                    return;
                }

                if (hasImages && DYYYGetBool(@"DYYYForceDownloadCommentImage")) {
                    NSDictionary *extraParams = [params extraParams];
                    BOOL isPicInflow = NO;
                    if (extraParams && [extraParams isKindOfClass:[NSDictionary class]]) {
                        id isPicInflowValue = extraParams[@"is_pic_inflow"];
                        if (isPicInflowValue) {
                            isPicInflow = [isPicInflowValue integerValue] == 1;
                        }
                    }

                    NSInteger currentIndex = -1;

                    if (isPicInflow) {
                        UIViewController *topVC = [DYYYUtils topView];
                        Class ivarClass = NSClassFromString(@"AWECommentMediaFeedSwfitImpl.CommentMediaFeedCellViewController");
                        Class targetClass = NSClassFromString(@"AWECommentMediaFeedSwfitImpl.CommentMediaFeedCommonImageCellViewController");

                        if (ivarClass && targetClass && topVC) {
                            Ivar multiIndexIvar = class_getInstanceVariable(ivarClass, "currentIndexInMultiImageList");
                            if (multiIndexIvar) {
                                UIViewController *cellVC = [DYYYUtils findViewControllerOfClass:targetClass inViewController:topVC];
                                if (cellVC) {
                                    ptrdiff_t offset = ivar_getOffset(multiIndexIvar);
                                    NSInteger *ptr = (NSInteger *)((char *)(__bridge void *)cellVC + offset);
                                    currentIndex = *ptr;
                                }
                            }
                        }
                    }

                    NSString *hint = (currentIndex >= 0) ? @"正在保存当前图片..." :
                        [NSString stringWithFormat:@"正在保存 %lu 张图片...", (unsigned long)imageList.count];
                    [DYYYUtils showToast:hint];

                    [DYYYManager saveCommentImages:imageList
                                      currentIndex:currentIndex
                                      completion:^(NSInteger successCount, NSInteger livePhotoCount, NSInteger failedCount) {
                        NSMutableString *message = [NSMutableString stringWithFormat:@"成功保存 %ld 张", (long)successCount];
                        if (livePhotoCount > 0) {
                            [message appendFormat:@"\n(含 %ld 张实况照片)", (long)livePhotoCount];
                        }
                        if (failedCount > 0) {
                            [message appendFormat:@"\n失败 %ld 张", (long)failedCount];
                        }
                        [DYYYUtils showToast:message];
                    }];
                    return;
                }
            } @catch (NSException *exception) {
                NSLog(@"[DYYY] SAFE MODE: CommentSaveImage.elementTapped exception: %@", exception.reason);
            }
        } featureName:@"CommentSaveImage_elementTapped"];
    }
}

+ (void)setupCommentHeaderGeneralHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentHeaderGeneral hook...");

    Class targetClass = DYYYGetClassFromCandidates(@[
        @"AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView",
        @"AWECommentPanelHeaderSwiftImpl.CommentHeaderGeneralView"
    ]);

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentHeaderGeneral class not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentHeaderGeneral"];
        return;
    }

    SEL selector = @selector(layoutSubviews);
    if (!class_respondsToSelector(targetClass, selector)) {
        NSLog(@"[DYYY] SAFE MODE: CommentHeaderGeneral.layoutSubviews not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentHeaderGeneral"];
        return;
    }

    [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                     selector:selector
                                                  replacement:^(id self) {
        if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentHeaderGeneral"]) {
            return;
        }

        @try {
            if (DYYYGetBool(@"DYYYHideCommentViews")) {
                [self setHidden:YES];
            }
        } @catch (NSException *exception) {
            NSLog(@"[DYYY] SAFE MODE: CommentHeaderGeneral exception: %@", exception.reason);
        }
    } featureName:@"CommentHeaderGeneral"];
}

+ (void)setupCommentHeaderGoodsHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentHeaderGoods hook...");

    Class targetClass = DYYYGetClassFromCandidates(@[
        @"AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView",
        @"AWECommentPanelHeaderSwiftImpl.CommentHeaderGoodsView"
    ]);

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentHeaderGoods class not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentHeaderGoods"];
        return;
    }

    SEL selector = @selector(layoutSubviews);
    if (!class_respondsToSelector(targetClass, selector)) {
        NSLog(@"[DYYY] SAFE MODE: CommentHeaderGoods.layoutSubviews not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentHeaderGoods"];
        return;
    }

    [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                     selector:selector
                                                  replacement:^(id self) {
        if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentHeaderGoods"]) {
            return;
        }

        @try {
            if (DYYYGetBool(@"DYYYHideCommentViews")) {
                [self setHidden:YES];
            }
        } @catch (NSException *exception) {
            NSLog(@"[DYYY] SAFE MODE: CommentHeaderGoods exception: %@", exception.reason);
        }
    } featureName:@"CommentHeaderGoods"];
}

+ (void)setupCommentHeaderTemplateHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentHeaderTemplate hook...");

    Class targetClass = DYYYGetClassFromCandidates(@[
        @"AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView",
        @"AWECommentPanelHeaderSwiftImpl.CommentHeaderTemplateAnchorView"
    ]);

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentHeaderTemplate class not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentHeaderTemplate"];
        return;
    }

    SEL selector = @selector(layoutSubviews);
    if (!class_respondsToSelector(targetClass, selector)) {
        NSLog(@"[DYYY] SAFE MODE: CommentHeaderTemplate.layoutSubviews not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentHeaderTemplate"];
        return;
    }

    [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                     selector:selector
                                                  replacement:^(id self) {
        if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentHeaderTemplate"]) {
            return;
        }

        @try {
            if (DYYYGetBool(@"DYYYHideCommentViews")) {
                [self setHidden:YES];
            }
        } @catch (NSException *exception) {
            NSLog(@"[DYYY] SAFE MODE: CommentHeaderTemplate exception: %@", exception.reason);
        }
    } featureName:@"CommentHeaderTemplate"];
}

+ (void)setupCommentBottomTipsHook {
    NSLog(@"[DYYY] SAFE MODE: Setting up CommentBottomTips hook...");

    Class targetClass = DYYYGetClassFromCandidates(@[
        @"AWECommentPanelListSwiftImpl_CommentBottomTipsContainerViewController",
        @"AWECommentPanelListSwiftImpl.CommentBottomTipsContainerViewController"
    ]);

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: CommentBottomTips class not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentBottomTips"];
        return;
    }

    SEL selector = @selector(viewWillAppear:);
    if (!class_respondsToSelector(targetClass, selector)) {
        NSLog(@"[DYYY] SAFE MODE: CommentBottomTips.viewWillAppear: not found");
        [[DYYYSwiftHookManager sharedManager] disableFeature:@"CommentBottomTips"];
        return;
    }

    [[DYYYSwiftHookManager sharedManager] safeHookSwiftClass:targetClass
                                                     selector:selector
                                                  replacement:^(id self, BOOL animated) {
        if (![[DYYYSwiftHookManager sharedManager] isFeatureAvailable:@"CommentBottomTips"]) {
            return;
        }

        @try {
            if (DYYYGetBool(@"DYYYHideCommentTips")) {
                ((UIViewController *)self).view.hidden = YES;
            }
        } @catch (NSException *exception) {
            NSLog(@"[DYYY] SAFE MODE: CommentBottomTips exception: %@", exception.reason);
        }
    } featureName:@"CommentBottomTips"];
}

@end
