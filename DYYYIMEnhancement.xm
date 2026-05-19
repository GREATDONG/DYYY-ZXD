//
//  DYYYIMEnhancement.xm  (修复版 v2)
//  DYYY IM 聊天增强功能
//
//  修复内容：
//  1. %ctor 无条件初始化所有 group（修复功能永远不加载的致命 bug）
//  2. 在 hook 内部检查开关（而非在 %ctor 中检查）
//  3. Hook UITableView 而非猜测 Cell 类名，覆盖所有聊天 Cell
//  4. 使用 NSNotificationCenter 广播引用/撤回事件
//  5. 移除空 group 和过于激进的 NSURLSession hook
//
//  Created by DYYY Team on 2026/05/01
//  Fixed on 2026/05/19
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

#pragma mark - Associated Object Keys

static char kDYYYLeftSwipeInstalledKey;
static char kDYYYRightSwipeInstalledKey;

#pragma mark - 辅助函数

// 从视图层级中递归查找聊天页面控制器
static UIViewController *DYYYFindIMChatViewController(UIView *view) {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            NSString *className = NSStringFromClass([responder class]);
            // 匹配 IM 聊天相关控制器
            if ([className containsString:@"IM"] &&
                ([className containsString:@"Chat"] ||
                 [className containsString:@"Conversation"] ||
                 [className containsString:@"Message"])) {
                return (UIViewController *)responder;
            }
        }
        responder = [responder nextResponder];
    }
    return nil;
}

// 从 Cell 中尝试获取消息对象
static id DYYYGetMessageFromCell(UITableViewCell *cell) {
    if (!cell) return nil;

    // 方法1: context.message
    SEL contextSel = NSSelectorFromString(@"context");
    if ([cell respondsToSelector:contextSel]) {
        id context = ((id (*)(id, SEL))objc_msgSend)(cell, contextSel);
        if (context) {
            SEL messageSel = NSSelectorFromString(@"message");
            if ([context respondsToSelector:messageSel]) {
                return ((id (*)(id, SEL))objc_msgSend)(context, messageSel);
            }
        }
    }

    // 方法2: 直接 message
    SEL msgSel = NSSelectorFromString(@"message");
    if ([cell respondsToSelector:msgSel]) {
        return ((id (*)(id, SEL))objc_msgSend)(cell, msgSel);
    }

    // 方法3: viewModel.message
    SEL vmSel = NSSelectorFromString(@"viewModel");
    if ([cell respondsToSelector:vmSel]) {
        id vm = ((id (*)(id, SEL))objc_msgSend)(cell, vmSel);
        if (vm && [vm respondsToSelector:msgSel]) {
            return ((id (*)(id, SEL))objc_msgSend)(vm, msgSel);
        }
    }

    // 方法4: model.message
    SEL modelSel = NSSelectorFromString(@"model");
    if ([cell respondsToSelector:modelSel]) {
        id model = ((id (*)(id, SEL))objc_msgSend)(cell, modelSel);
        if (model && [model respondsToSelector:msgSel]) {
            return ((id (*)(id, SEL))objc_msgSend)(model, msgSel);
        }
    }

    return nil;
}

// 获取消息文本内容
static NSString *DYYYGetMessageContent(id message) {
    if (!message) return nil;

    SEL contentSel = NSSelectorFromString(@"content");
    if ([message respondsToSelector:contentSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, contentSel);
    }

    SEL textSel = NSSelectorFromString(@"text");
    if ([message respondsToSelector:textSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, textSel);
    }

    return nil;
}

// 获取消息发送者 ID
static NSString *DYYYGetMessageSenderID(id message) {
    if (!message) return nil;

    SEL fromUserSel = NSSelectorFromString(@"fromUserId");
    if ([message respondsToSelector:fromUserSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, fromUserSel);
    }

    SEL senderSel = NSSelectorFromString(@"senderId");
    if ([message respondsToSelector:senderSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, senderSel);
    }

    SEL userSel = NSSelectorFromString(@"user");
    if ([message respondsToSelector:userSel]) {
        id user = ((id (*)(id, SEL))objc_msgSend)(message, userSel);
        if (user) {
            SEL uidSel = NSSelectorFromString(@"userId");
            if ([user respondsToSelector:uidSel]) {
                return ((NSString *(*)(id, SEL))objc_msgSend)(user, uidSel);
            }
        }
    }

    return nil;
}

// 获取当前登录用户 ID
static NSString *DYYYGetCurrentUserID(void) {
    Class cls = objc_getClass("AWEAccountService");
    if (!cls) cls = objc_getClass("AWELoginService");
    if (!cls) return nil;

    SEL sharedSel = NSSelectorFromString(@"sharedInstance");
    if (!class_getClassMethod(cls, sharedSel)) {
        sharedSel = NSSelectorFromString(@"shared");
    }
    if (!class_getClassMethod(cls, sharedSel)) return nil;

    id service = ((id (*)(id, SEL))objc_msgSend)(cls, sharedSel);
    if (!service) return nil;

    SEL uidSel = NSSelectorFromString(@"userId");
    if ([service respondsToSelector:uidSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(service, uidSel);
    }

    SEL curUidSel = NSSelectorFromString(@"currentUserId");
    if ([service respondsToSelector:curUidSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(service, curUidSel);
    }

    return nil;
}

// 获取消息 ID
static NSString *DYYYGetMessageID(id message) {
    if (!message) return nil;

    SEL msgIdSel = NSSelectorFromString(@"msgId");
    if ([message respondsToSelector:msgIdSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, msgIdSel);
    }

    SEL idSel = NSSelectorFromString(@"messageId");
    if ([message respondsToSelector:idSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, idSel);
    }

    return nil;
}

// 判断消息是否为自己发送
static BOOL DYYYIsMyMessage(id message) {
    NSString *senderId = DYYYGetMessageSenderID(message);
    NSString *myId = DYYYGetCurrentUserID();
    if (senderId && myId) {
        return [senderId isEqualToString:myId];
    }
    // 备用：检查 isOutgoing / isSend 属性
    SEL outgoingSel = NSSelectorFromString(@"isOutgoing");
    if ([message respondsToSelector:outgoingSel]) {
        return ((BOOL (*)(id, SEL))objc_msgSend)(message, outgoingSel);
    }
    SEL sendSel = NSSelectorFromString(@"isSend");
    if ([message respondsToSelector:sendSel]) {
        return ((BOOL (*)(id, SEL))objc_msgSend)(message, sendSel);
    }
    return NO;
}

#pragma mark - 功能1: 聊天消息左滑引用 / 右滑撤回

%group DYYYIMSwipeActionsGroup

// Hook 所有 UITableView，在 IM 聊天页面中为 Cell 添加手势
%hook UITableView

- (void)layoutSubviews {
    %orig;

    // 检查总开关
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;

    // 判断当前 TableView 是否在 IM 聊天页面中
    UIViewController *vc = DYYYFindIMChatViewController(self);
    if (!vc) return;

    // 遍历所有可见 Cell，添加手势
    for (UITableViewCell *cell in self.visibleCells) {
        [self dyyy_installSwipeGesturesIfNeeded:cell];
    }
}

%new
- (void)dyyy_installSwipeGesturesIfNeeded:(UITableViewCell *)cell {
    if (!cell) return;

    // 左滑手势 → 引用
    if (DYYYGetBool(@"DYYYEnableSwipeActions")) {
        BOOL leftInstalled = [objc_getAssociatedObject(cell, &kDYYYLeftSwipeInstalledKey) boolValue];
        if (!leftInstalled) {
            UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
                initWithTarget:self
                action:@selector(dyyy_handleLeftSwipe:)];
            leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
            [cell addGestureRecognizer:leftSwipe];
            objc_setAssociatedObject(cell, &kDYYYLeftSwipeInstalledKey, @YES, OBJC_ASSOCIATION_RETAIN);
        }
    }

    // 右滑手势 → 撤回
    if (DYYYGetBool(@"DYYYEnableSwipeActions")) {
        BOOL rightInstalled = [objc_getAssociatedObject(cell, &kDYYYRightSwipeInstalledKey) boolValue];
        if (!rightInstalled) {
            UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
                initWithTarget:self
                action:@selector(dyyy_handleRightSwipe:)];
            rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
            [cell addGestureRecognizer:rightSwipe];
            objc_setAssociatedObject(cell, &kDYYYRightSwipeInstalledKey, @YES, OBJC_ASSOCIATION_RETAIN);
        }
    }
}

// 左滑 → 引用消息
%new
- (void)dyyy_handleLeftSwipe:(UISwipeGestureRecognizer *)gesture {
    UITableViewCell *cell = (UITableViewCell *)gesture.view;
    if (![cell isKindOfClass:[UITableViewCell class]]) return;

    id message = DYYYGetMessageFromCell(cell);
    if (!message) {
        [DYYYUtils showToast:@"无法获取消息内容"];
        return;
    }

    NSString *content = DYYYGetMessageContent(message);
    NSString *msgId = DYYYGetMessageID(message);

    if (!content && !msgId) {
        [DYYYUtils showToast:@"该消息类型不支持引用"];
        return;
    }

    // 发送引用通知，让聊天页面控制器处理
    NSString *displayText = content ?: @"[消息]";
    if (displayText.length > 30) {
        displayText = [[displayText substringToIndex:30] stringByAppendingString:@"..."];
    }

    NSDictionary *userInfo = @{
        @"message": message ?: [NSNull null],
        @"messageId": msgId ?: @"",
        @"content": displayText
    };

    [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYQuoteMessageNotification"
                                                        object:nil
                                                      userInfo:userInfo];

    [DYYYUtils showToast:[NSString stringWithFormat:@"引用: %@", displayText]];

    // 触觉反馈
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
}

// 右滑 → 撤回消息
%new
- (void)dyyy_handleRightSwipe:(UISwipeGestureRecognizer *)gesture {
    UITableViewCell *cell = (UITableViewCell *)gesture.view;
    if (![cell isKindOfClass:[UITableViewCell class]]) return;

    id message = DYYYGetMessageFromCell(cell);
    if (!message) {
        [DYYYUtils showToast:@"无法获取消息内容"];
        return;
    }

    // 检查是否是自己的消息
    if (!DYYYIsMyMessage(message)) {
        [DYYYUtils showToast:@"只能撤回自己的消息"];
        return;
    }

    NSString *msgId = DYYYGetMessageID(message);
    if (!msgId) {
        [DYYYUtils showToast:@"无法获取消息ID"];
        return;
    }

    // 触觉反馈
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];

    // 弹出确认对话框
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"撤回消息"
            message:@"确定要撤回这条消息吗？"
            preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

        [alert addAction:[UIAlertAction actionWithTitle:@"撤回" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            // 发送撤回通知
            NSDictionary *userInfo = @{
                @"message": message ?: [NSNull null],
                @"messageId": msgId ?: @""
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYRecallMessageNotification"
                                                                object:nil
                                                              userInfo:userInfo];
            [DYYYUtils showToast:@"正在撤回..."];
        }]];

        UIViewController *topVC = [DYYYUtils topView];
        if (topVC) {
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

%end // UITableView hook

%end // DYYYIMSwipeActionsGroup


#pragma mark - 功能2: 阻止已读回执上传

%group DYYYBlockReadReceiptGroup

// Hook 已读回执上报类
%hook AWEIMReadReceiptDataCenter

- (void)reportReadReceipt:(id)arg1 {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] 已拦截已读回执上报");
        return;
    }
    %orig;
}

- (void)ackRead:(id)arg1 {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] 已拦截已读确认");
        return;
    }
    %orig;
}

- (void)sendReadReceipt:(id)arg1 {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] 已拦截发送已读回执");
        return;
    }
    %orig;
}

%end

%hook AWEIMConversation

- (void)markConversationRead {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] 已拦截会话已读标记");
        return;
    }
    %orig;
}

%end

%end // DYYYBlockReadReceiptGroup


#pragma mark - 功能3: 阻止访客记录上传

%group DYYYBlockVisitorUploadGroup

%hook AWEProfileNavVisitorItemController

- (void)reportVisit {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY] 已拦截主页访客上报");
        return;
    }
    %orig;
}

- (void)didEnterVisitorsPage {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY] 已拦截进入访客页面上报");
        return;
    }
    %orig;
}

%end

%end // DYYYBlockVisitorUploadGroup


#pragma mark - 构造函数：无条件初始化所有 group

%ctor {
    NSLog(@"[DYYY-IM] 正在初始化 IM 增强模块...");

    // ★ 关键修复：无条件初始化所有 group
    // 开关检查在 hook 内部进行，而不是在 %ctor 中
    %init(DYYYIMSwipeActionsGroup);
    %init(DYYYBlockReadReceiptGroup);
    %init(DYYYBlockVisitorUploadGroup);

    NSLog(@"[DYYY-IM] IM 增强模块初始化完成");
}
