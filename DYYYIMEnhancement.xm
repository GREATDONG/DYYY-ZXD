//
//  DYYYIMEnhancement.xm  (修复版 v3)
//  DYYY IM 聊天增强功能
//
//  修复内容：
//  1. %ctor 无条件初始化所有 group（修复条件判断导致的问题）
//  2. 使用 UITableView 替代 AWEIMReusableCommonCell（修复类名错误）
//  3. 使用 NSNotificationCenter 替代直接调用方法（避免方法不存在崩溃）
//  4. 添加 @"" 前缀到所有 ObjC 字符串字面量
//  5. 添加完整的 read receipt 和 visitor upload 拦截逻辑
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

// Associated Object Keys
static char kDYYYSwipeGestureKey;
static char kDYYYMessageCellKey;

// ============================================================
// 辅助函数：查找 IM 聊天视图控制器
// ============================================================
static UIViewController *DYYYFindIMChatViewController(UIView *view) {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            // 检查是否是聊天页面控制器
            if ([NSStringFromClass([vc class]) containsString:@"IM"] ||
                [NSStringFromClass([vc class]) containsString:@"Chat"]) {
                return vc;
            }
        }
        responder = [responder nextResponder];
    }
    return nil;
}

// ============================================================
// 辅助函数：从 Cell 获取消息对象
// ============================================================
static id DYYYGetMessageFromCell(id cell) {
    if (!cell) return nil;
    
    // 尝试获取 message
    SEL msgSel = NSSelectorFromString(@"message");
    if ([cell respondsToSelector:msgSel]) {
        return ((id (*)(id, SEL))objc_msgSend)(cell, msgSel);
    }
    
    // 尝试获取 model
    SEL modelSel = NSSelectorFromString(@"model");
    if ([cell respondsToSelector:modelSel]) {
        id model = ((id (*)(id, SEL))objc_msgSend)(cell, modelSel);
        if (model && [model respondsToSelector:msgSel]) {
            return ((id (*)(id, SEL))objc_msgSend)(model, msgSel);
        }
    }
    
    return nil;
}

// ============================================================
// 功能1: 聊天消息左滑引用 / 右滑撤回
// ============================================================
%group DYYYIMSwipeActionsGroup

// Hook UITableView 来添加滑动手势
%hook UITableView

- (void)layoutSubviews {
    %orig;
    
    // 检查功能开关
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    
    // 检查是否在 IM 聊天页面
    UIViewController *vc = DYYYFindIMChatViewController(self);
    if (!vc) return;
    
    // 避免重复添加手势
    if (objc_getAssociatedObject(self, &kDYYYSwipeGestureKey)) return;
    objc_setAssociatedObject(self, &kDYYYSwipeGestureKey, @YES, OBJC_ASSOCIATION_RETAIN);
    
    // 添加滑动手势识别器
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(dyyy_handleLeftSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftSwipe];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
                                            initWithTarget:self
                                            action:@selector(dyyy_handleRightSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipe];
}

%new
- (void)dyyy_handleLeftSwipe:(UISwipeGestureRecognizer *)gesture {
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    
    NSString *leftAction = DYYYGetString(@"DYYYSwipeLeftAction");
    if (![leftAction isEqualToString:@"quote"]) return;
    
    // 获取滑动位置的 Cell
    CGPoint location = [gesture locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    if (!indexPath) return;
    
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    if (!cell) return;
    
    id message = DYYYGetMessageFromCell(cell);
    if (!message) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息"];
        return;
    }
    
    // 发送引用通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYQuoteMessage"
                                                        object:nil
                                                      userInfo:@{@"message": message,
                                                                @"cell": cell}];
    
    [DYYYToast showSuccessToastWithMessage:@"已引用消息"];
}

%new
- (void)dyyy_handleRightSwipe:(UISwipeGestureRecognizer *)gesture {
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    
    NSString *rightAction = DYYYGetString(@"DYYYSwipeRightAction");
    if (![rightAction isEqualToString:@"recall"]) return;
    
    // 获取滑动位置的 Cell
    CGPoint location = [gesture locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    if (!indexPath) return;
    
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    if (!cell) return;
    
    id message = DYYYGetMessageFromCell(cell);
    if (!message) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息"];
        return;
    }
    
    // 发送撤回通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYRecallMessage"
                                                        object:nil
                                                      userInfo:@{@"message": message,
                                                                @"cell": cell}];
    
    [DYYYToast showSuccessToastWithMessage:@"已撤回消息"];
}

%end

%end // DYYYIMSwipeActionsGroup


// ============================================================
// 功能2: 阻止已读回执上传
// ============================================================
%group DYYYBlockReadReceiptGroup

// Hook 已读回执上报方法
%hook AWEIMReadReceiptDataCenter

- (void)reportReadReceipt:(id)receipt {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked read receipt report");
        return;
    }
    %orig;
}

- (void)ackRead:(id)message {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked read ack");
        return;
    }
    %orig;
}

- (void)sendReadReceipt:(id)receipt {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked send read receipt");
        return;
    }
    %orig;
}

%end

// Hook 会话已读标记
%hook AWEIMConversation

- (void)markConversationRead {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked conversation read mark");
        return;
    }
    %orig;
}

- (void)markMessagesAsRead:(id)messages {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked mark messages as read");
        return;
    }
    %orig;
}

%end

%end // DYYYBlockReadReceiptGroup


// ============================================================
// 功能3: 阻止访客记录上传
// ============================================================
%group DYYYBlockVisitorUploadGroup

// Hook 访客控制器
%hook AWEProfileNavVisitorItemController

- (void)reportVisit {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] Blocked profile visit report");
        return;
    }
    %orig;
}

- (void)didEnterVisitorsPage {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] Blocked enter visitors page");
        return;
    }
    %orig;
}

%end

// Hook 访客数据管理器
%hook AWEIMVisitorDataCenter

- (void)uploadVisitorRecord:(id)record {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] Blocked visitor record upload");
        return;
    }
    %orig;
}

- (void)reportVisitor:(id)visitor {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] Blocked visitor report");
        return;
    }
    %orig;
}

%end

%end // DYYYBlockVisitorUploadGroup


// ============================================================
// 构造函数：无条件初始化所有 group
// ============================================================
%ctor {
    NSLog(@"[DYYY-IM] 正在初始化 IM 增强模块...");
    
    // 无条件初始化所有 group - 这是修复的关键！
    %init(DYYYIMSwipeActionsGroup);
    %init(DYYYBlockReadReceiptGroup);
    %init(DYYYBlockVisitorUploadGroup);
    
    NSLog(@"[DYYY-IM] IM 增强模块初始化完成");
}
