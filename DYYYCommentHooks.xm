//
//  DYYYCommentHooks.xm
//  DYYY
//
//  评论相关 Hooks 模块
//  包含：评论复制、表情保存、图片保存、评论菜单等
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
#import "DYYYSwiftHookManager.h"

#pragma mark - 评论长按复制（Swift Hook - 安全模式）

%hook _TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement

- (void)elementTapped {
    if (DYYYGetBool(@"DYYYCommentCopyText")) {
        AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
        AWECommentModel *selectdComment = [commentPageContext selectdComment];
        if (!selectdComment) {
            AWECommentLongPressPanelParam *params = [commentPageContext params];
            selectdComment = [params selectdComment];
        }
        NSString *descText = [selectdComment content];
        [[UIPasteboard generalPasteboard] setString:descText];
        [DYYYToast showSuccessToastWithMessage:@"评论已复制"];
    }
}

%end

#pragma mark - 评论表情长按（Swift Hook - 安全模式）

%group EnableStickerSaveMenu
static __weak YYAnimatedImageView *targetStickerView = nil;
static BOOL dyyyShouldUseLastStickerURL = NO;

%hook _TtCV28AWECommentPanelListSwiftImpl6NEWAPI27CommentCellStickerComponent

- (void)handleLongPressWithGes:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([gesture.view isKindOfClass:NSClassFromString(@"YYAnimatedImageView")]) {
            targetStickerView = (YYAnimatedImageView *)gesture.view;
            NSLog(@"DYYY 长按表情：%@", targetStickerView);
        } else {
            targetStickerView = nil;
        }
    }

    %orig;
}

%end

#pragma mark - 评论保存图片/表情/音频（Swift Hook - 安全模式）

%hook _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement

- (BOOL)elementShouldShow {
    BOOL shouldShow = %orig;
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
}

- (void)elementTapped {
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

    %orig;
}

%end

%end

#pragma mark - 评论头部视图（Swift Hook - 安全模式）

%group CommentHeaderGeneralGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}

%end
%end

%group CommentHeaderGoodsGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}

%end
%end

%group CommentHeaderTemplateGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}

%end
%end

%group CommentBottomTipsVCGroup
%hook AWECommentPanelListSwiftImpl_CommentBottomTipsContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    if (DYYYGetBool(@"DYYYHideCommentTips")) {
        ((UIViewController *)self).view.hidden = YES;
    }
}

%end
%end

#pragma mark - 评论标签

%hook AWECommentSwiftBizUI_CommentInteractionBaseLabel

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYModifyCommentLabel")) {
        return;
    }
}

%end

#pragma mark - 评论图片模型

%hook AWECommentImageModel

- (id)downloadUrl {
    if (DYYYGetBool(@"DYYYCommentNotWaterMark")) {
        return self.originUrl;
    }
    return %orig;
}

%end

#pragma mark - 评论实况照片

%hook AWECommentMediaDownloadConfigLivePhoto

- (id)watermarkConfig {
    return commentLivePhotoNotWaterMark ? nil : %orig;
}

%end

#pragma mark - 评论菜单

%hook UIMenu

+ (instancetype)menuWithTitle:(NSString *)title image:(UIImage *)image identifier:(UIMenuIdentifier)identifier options:(UIMenuOptions)options children:(NSArray<UIMenuElement *> *)children {
    BOOL hasAddStickerOption = NO;
    BOOL hasSaveLocalOption = NO;

    for (UIMenuElement *element in children) {
        NSString *elementTitle = nil;

        if ([element isKindOfClass:[UIAction class]]) {
            elementTitle = [(UIAction *)element title];
        } else if ([element isKindOfClass:[UICommand class]]) {
            elementTitle = [(UICommand *)element title];
        }

        if ([elementTitle isEqualToString:@"添加到表情"]) {
            hasAddStickerOption = YES;
        } else if ([elementTitle isEqualToString:@"保存到相册"]) {
            hasSaveLocalOption = YES;
        }
    }

    if (hasAddStickerOption && !hasSaveLocalOption) {
        NSMutableArray *newChildren = [children mutableCopy];

        if (DYYYGetBool(@"DYYYForceDownloadEmotion")) {
            UIAction *saveAction = [UIAction actionWithTitle:@"保存到相册"
                                                       image:nil
                                                  identifier:nil
                                                     handler:^(__kindof UIAction *action) {
                for (UIAction *child in children) {
                    if ([child.title isEqualToString:@"添加到表情"]) {
                        [child performSelector:@selector(handler:) withObject:action];
                        break;
                    }
                }
            }];
            [newChildren addObject:saveAction];
        }

        return %orig;
    }

    return %orig;
}

%end

#pragma mark - 表情预览

%hook AWEIMEmoticonPreviewV2

- (void)showEmoticonPreview:(id)arg1 {
    if (DYYYGetBool(@"DYY YHideEmoticonPreview")) {
        return;
    }
    %orig;
}

%end

#pragma mark - 自定义菜单组件

%hook AWEIMCustomMenuComponent

- (void)updateMenuItems:(id)arg1 {
    %orig;
}

%end
