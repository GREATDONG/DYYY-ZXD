//
//  DYYYIMEnhancement.xm
//  DYYY IM 聊天增强功能
//
//  功能列表：
//  1. 左滑引用 / 右滑撤回消息
//  2. 阻止已读回执上传
//  3. 阻止访客记录上传
//
//  Created by DYYY Team on 2026/05/01
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

// Associated Object Keys（必须用静态变量地址）
static char kDYYYSwipeGestureKey;

// ============================================================
// 功能1: 聊天消息左滑引用 / 右滑撤回
// ============================================================

// 辅助函数：从 Cell 获取消息对象
static id DYYYGetMessageFromCell(id cell) {
    if (!cell) return nil;
    
    // 尝试通过 context 获取
    SEL contextSel = NSSelectorFromString(@"context");
    if ([cell respondsToSelector:contextSel]) {
        id context = ((id (*)(id, SEL))objc_msgSend)(cell, contextSel);
        if (context) {
            SEL messageSel = NSSelectorFromString(@"message");
            if ([context respondsToSelector:messageSel]) {
                return ((id (*)(id, SEL))objc_msgSend)(context, messageSel);
            }
            // componentContext
            id compCtx = nil;
            SEL compCtxSel = NSSelectorFromString(@"componentContext");
            if ([context respondsToSelector:compCtxSel]) {
                compCtx = ((id (*)(id, SEL))objc_msgSend)(context, compCtxSel);
            }
            if (compCtx && [compCtx respondsToSelector:messageSel]) {
                return ((id (*)(id, SEL))objc_msgSend)(compCtx, messageSel);
            }
        }
    }
    
    // 尝试直接获取 message
    SEL msgSel = NSSelectorFromString(@"message");
    if ([cell respondsToSelector:msgSel]) {
        return ((id (*)(id, SEL))objc_msgSend)(cell, msgSel);
    }
    
    // 尝试 model
    SEL modelSel = NSSelectorFromString(@"model");
    if ([cell respondsToSelector:modelSel]) {
        id model = ((id (*)(id, SEL))objc_msgSend)(cell, modelSel);
        if (model && [model respondsToSelector:msgSel]) {
            return ((id (*)(id, SEL))objc_msgSend)(model, msgSel);
        }
    }
    
    return nil;
}

// 辅助：获取消息发送者ID
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
    
    // user.userId
    SEL userSel = NSSelectorFromString(@"user");
    if ([message respondsToSelector:userSel]) {
        id user = ((id (*)(id, SEL))objc_msgSend)(message, userSel);
        if (user) {
            SEL userIdSel = NSSelectorFromString(@"userId");
            if ([user respondsToSelector:userIdSel]) {
                return ((NSString *(*)(id, SEL))objc_msgSend)(user, userIdSel);
            }
        }
    }
    
    return nil;
}

// 辅助：获取当前登录用户ID
static NSString *DYYYGetCurrentUserID() {
    Class accountServiceClass = objc_getClass("AWEAccountService");
    if (!accountServiceClass) {
        accountServiceClass = objc_getClass("AWELoginService");
    }
    
    if (accountServiceClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if (!sharedSel) sharedSel = NSSelectorFromString(@"shared");
        
        if (class_getClassMethod(accountServiceClass, sharedSel)) {
            id service = ((id (*)(id, SEL))objc_msgSend)(accountServiceClass, sharedSel);
            if (service) {
                SEL userIdSel = NSSelectorFromString(@"userId");
                if ([service respondsToSelector:userIdSel]) {
                    return ((NSString *(*)(id, SEL))objc_msgSend)(service, userIdSel);
                }
                SEL currentUserIdSel = NSSelectorFromString(@"currentUserId");
                if ([service respondsToSelector:currentUserIdSel]) {
                    return ((NSString *(*)(id, SEL))objc_msgSend)(service, currentUserIdSel);
                }
            }
        }
    }
    
    return nil;
}

// 辅助：获取消息ID
static NSString *DYYYGetMessageID(id message) {
    if (!message) return nil;
    
    SEL msgIdSel = NSSelectorFromString(@"msgId");
    if ([message respondsToSelector:msgIdSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, msgIdSel);
    }
    
    SEL idSel = NSSelectorFromString(@"Id");
    if ([message respondsToSelector:idSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, idSel);
    }
    
    return nil;
}

// 辅助：引用消息
static void DYYYQuoteMessage(id cell, id message) {
    NSString *msgId = DYYYGetMessageID(message);
    if (!msgId) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息ID"];
        return;
    }
    
    // 尝试调用 Cell 的引用方法
    SEL quoteSel = NSSelectorFromString(@"quoteMessage");
    if ([cell respondsToSelector:quoteSel]) {
        ((void (*)(id, SEL))objc_msgSend)(cell, quoteSel);
        return;
    }
    
    // 尝试调用 context 的引用方法
    SEL contextSel = NSSelectorFromString(@"context");
    if ([cell respondsToSelector:contextSel]) {
        id context = ((id (*)(id, SEL))objc_msgSend)(cell, contextSel);
        if (context && [context respondsToSelector:quoteSel]) {
            ((void (*)(id, SEL))objc_msgSend)(context, quoteSel);
            return;
        }
    }
    
    // 尝试调用会话的引用方法
    SEL convSel = NSSelectorFromString(@"conversation");
    if ([cell respondsToSelector:convSel]) {
        id conv = ((id (*)(id, SEL))objc_msgSend)(cell, convSel);
        if (conv) {
            SEL replySel = NSSelectorFromString(@"replyToMessage:");
            if ([conv respondsToSelector:replySel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(conv, replySel, message);
                return;
            }
        }
    }
    
    [DYYYToast showSuccessToastWithMessage:@"引用功能不可用"];
}

// 辅助：撤回消息
static void DYYYRecallMessage(id cell, id message) {
    NSString *senderId = DYYYGetMessageSenderID(message);
    NSString *currentUserId = DYYYGetCurrentUserID();
    
    // 只能撤回自己发送的消息
    if (senderId && currentUserId && ![senderId isEqualToString:currentUserId]) {
        [DYYYToast showSuccessToastWithMessage:@"只能撤回自己的消息"];
        return;
    }
    
    NSString *msgId = DYYYGetMessageID(message);
    if (!msgId) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息ID"];
        return;
    }
    
    // 尝试调用 Cell 的撤回方法
    SEL recallSel = NSSelectorFromString(@"recallMessage");
    if ([cell respondsToSelector:recallSel]) {
        ((void (*)(id, SEL))objc_msgSend)(cell, recallSel);
        return;
    }
    
    // 尝试调用会话的撤回方法
    SEL convSel = NSSelectorFromString(@"conversation");
    if ([cell respondsToSelector:convSel]) {
        id conv = ((id (*)(id, SEL))objc_msgSend)(cell, convSel);
        if (conv) {
            SEL revokeSel = NSSelectorFromString(@"revokeMessage:");
            if ([conv respondsToSelector:revokeSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(conv, revokeSel, message);
                return;
            }
        }
    }
    
    [DYYYToast showSuccessToastWithMessage:@"撤回功能不可用"];
}

// Hook 聊天 Cell 添加滑动手势
%group DYYYIMSwipeActionsGroup

%hook AWEIMReusableCommonCell

- (void)didMoveToSuperview {
    %orig;
    
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    
    // 避免重复添加手势
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]] &&
            [(NSString *)objc_getAssociatedObject(gesture, &kDYYYSwipeGestureKey) hasPrefix:@"DYYY"]) {
            return;
        }
    }
    
    NSString *leftAction = DYYYGetString(@"DYYYSwipeLeftAction");
    NSString *rightAction = DYYYGetString(@"DYYYSwipeRightAction");
    
    // 左滑手势 → 引用
    if ([leftAction isEqualToString:@"quote"]) {
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(dyyy_handleSwipeGesture:)];
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        objc_setAssociatedObject(leftSwipe, &kDYYYSwipeGestureKey, @"DYYYLeftSwipe", OBJC_ASSOCIATION_RETAIN);
        [self addGestureRecognizer:leftSwipe];
    }
    
    // 右滑手势 → 撤回
    if ([rightAction isEqualToString:@"recall"]) {
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(dyyy_handleSwipeGesture:)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        objc_setAssociatedObject(rightSwipe, &kDYYYSwipeGestureKey, @"DYYYRightSwipe", OBJC_ASSOCIATION_RETAIN);
        [self addGestureRecognizer:rightSwipe];
    }
}

%new
- (void)dyyy_handleSwipeGesture:(UISwipeGestureRecognizer *)gesture {
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    
    id message = DYYYGetMessageFromCell(self);
    if (!message) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息"];
        return;
    }
    
    NSString *gestureType = objc_getAssociatedObject(gesture, &kDYYYSwipeGestureKey);
    
    if ([gestureType isEqualToString:@"DYYYLeftSwipe"]) {
        // 左滑 → 引用
        DYYYQuoteMessage(self, message);
    } else if ([gestureType isEqualToString:@"DYYYRightSwipe"]) {
        // 右滑 → 撤回
        DYYYRecallMessage(self, message);
    }
}

%end

%end // DYYYIMSwipeActionsGroup

// ============================================================
// 功能2: 阻止已读回执上传
// ============================================================

// 使用运行时动态 swizzle 拦截已读回执
static IMP DYYYOrigReportReadReceipt = NULL;
static IMP DYYYOrigAckRead = NULL;
static IMP DYYYOrigSendReadReceipt = NULL;
static IMP DYYYOrigMarkConversationRead = NULL;

static void DYYYReplacedReportReadReceipt(id self, SEL _cmd, id arg1) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] Blocked read receipt report");
        return;
    }
    if (DYYYOrigReportReadReceipt) {
        ((void (*)(id, SEL, id))DYYYOrigReportReadReceipt)(self, _cmd, arg1);
    }
}

static void DYYYReplacedAckRead(id self, SEL _cmd, id arg1) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] Blocked read ack");
        return;
    }
    if (DYYYOrigAckRead) {
        ((void (*)(id, SEL, id))DYYYOrigAckRead)(self, _cmd, arg1);
    }
}

static void DYYYReplacedSendReadReceipt(id self, SEL _cmd, id arg1) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] Blocked send read receipt");
        return;
    }
    if (DYYYOrigSendReadReceipt) {
        ((void (*)(id, SEL, id))DYYYOrigSendReadReceipt)(self, _cmd, arg1);
    }
}

static void DYYYReplacedMarkConversationRead(id self, SEL _cmd) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY] Blocked conversation read mark");
        return;
    }
    if (DYYYOrigMarkConversationRead) {
        ((void (*)(id, SEL))DYYYOrigMarkConversationRead)(self, _cmd);
    }
}

static void DYYYSetupReadReceiptHooks() {
    // Hook AWEIMReadReceiptDataCenter 方法
    Class readReceiptClass = objc_getClass("AWEIMReadReceiptDataCenter");
    if (readReceiptClass) {
        // reportReadReceipt:
        SEL reportSel = NSSelectorFromString(@"reportReadReceipt:");
        if (class_getInstanceMethod(readReceiptClass, reportSel)) {
            Method origMethod = class_getInstanceMethod(readReceiptClass, reportSel);
            DYYYOrigReportReadReceipt = method_setImplementation(origMethod, (IMP)DYYYReplacedReportReadReceipt);
        }
        // ackRead:
        SEL ackSel = NSSelectorFromString(@"ackRead:");
        if (class_getInstanceMethod(readReceiptClass, ackSel)) {
            Method origMethod = class_getInstanceMethod(readReceiptClass, ackSel);
            DYYYOrigAckRead = method_setImplementation(origMethod, (IMP)DYYYReplacedAckRead);
        }
        // sendReadReceipt:
        SEL sendSel = NSSelectorFromString(@"sendReadReceipt:");
        if (class_getInstanceMethod(readReceiptClass, sendSel)) {
            Method origMethod = class_getInstanceMethod(readReceiptClass, sendSel);
            DYYYOrigSendReadReceipt = method_setImplementation(origMethod, (IMP)DYYYReplacedSendReadReceipt);
        }
    }
    
    // Hook AWEIMConversation markConversationRead
    Class convClass = objc_getClass("AWEIMConversation");
    if (convClass) {
        SEL markSel = NSSelectorFromString(@"markConversationRead");
        if (class_getInstanceMethod(convClass, markSel)) {
            Method origMethod = class_getInstanceMethod(convClass, markSel);
            DYYYOrigMarkConversationRead = method_setImplementation(origMethod, (IMP)DYYYReplacedMarkConversationRead);
        }
    }
}

%group DYYYBlockReadReceiptGroup
%end // DYYYBlockReadReceiptGroup

// ============================================================
// 功能3: 阻止访客记录上传
// ============================================================

%group DYYYBlockVisitorUploadGroup

// 策略1: Hook AWEProfileNavVisitorItemController — 主页访客入口控制器
%hook AWEProfileNavVisitorItemController

- (void)reportVisit {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY] Blocked profile visit report");
        return;
    }
    %orig;
}

// 拦截访客列表加载后的上报
- (void)didEnterVisitorsPage {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY] Blocked enter visitors page");
        return;
    }
    %orig;
}

%end

// 策略2: Hook NSURLSession 请求拦截
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    // 拦截访客上报请求
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSURL *url = request.URL;
        if (url) {
            NSString *host = url.host;
            NSString *path = url.path;
            // 精确匹配抖音访客上报 API（仅匹配 aweme 相关域名 + 访客路径）
            if ([host containsString:@"aweme"] && [path containsString:@"/visitor"]) {
                NSLog(@"[DYYY] Blocked visitor upload request: %@", url.absoluteString);
                // 返回空数据，模拟成功响应
                if (completionHandler) {
                    NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
                    completionHandler(nil, response, nil);
                }
                return nil;
            }
        }
    }
    return %orig;
}

%end

%end // DYYYBlockVisitorUploadGroup

// ============================================================
// 构造函数：初始化所有功能
// ============================================================

%ctor {
    // 初始化功能1: 滑动手势
    if (DYYYGetBool(@"DYYYEnableSwipeActions")) {
        %init(DYYYIMSwipeActionsGroup);
    }
    
    // 初始化功能2: 阻止已读回执
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        DYYYSetupReadReceiptHooks();
        %init(DYYYBlockReadReceiptGroup);
    }
    
    // 初始化功能3: 阻止访客记录
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        %init(DYYYBlockVisitorUploadGroup);
    }
}
