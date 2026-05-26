//
//  DYYYIMEnhancement.xm  (修复版 v4)
//  DYYY IM 聊天增强功能
//
//  修复内容：
//  1. 修复滑动手势默认值（当设置不存在时默认启用）
//  2. 使用 NSClassFromString 动态查找类，避免类不存在崩溃
//  3. 添加更详细的日志输出便于调试
//  4. 改进手势检测，支持更多视图类型
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
// 辅助函数：安全获取 BOOL 值（带默认值）
// ============================================================
static BOOL DYYYGetBoolWithDefault(NSString *key, BOOL defaultValue) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    if (value == nil) {
        return defaultValue;
    }
    return [value boolValue];
}

// ============================================================
// 辅助函数：安全获取字符串值（带默认值）
// ============================================================
static NSString *DYYYGetStringWithDefault(NSString *key, NSString *defaultValue) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *value = [defaults stringForKey:key];
    if (value == nil || value.length == 0) {
        return defaultValue;
    }
    return value;
}

// ============================================================
// 辅助函数：查找 IM 聊天视图控制器
// ============================================================
static UIViewController *DYYYFindIMChatViewController(UIView *view) {
    UIResponder *responder = view;
    int depth = 0;
    while (responder && depth < 20) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            NSString *className = NSStringFromClass([vc class]);
            // 检查是否是聊天页面控制器（多种可能的类名）
            if ([className containsString:@"IM"] ||
                [className containsString:@"Chat"] ||
                [className containsString:@"Message"] ||
                [className containsString:@"Conversation"]) {
                NSLog(@"[DYYY-IM] Found IM VC: %@", className);
                return vc;
            }
        }
        responder = [responder nextResponder];
        depth++;
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
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cell performSelector:msgSel];
        #pragma clang diagnostic pop
    }
    
    // 尝试获取 model
    SEL modelSel = NSSelectorFromString(@"model");
    if ([cell respondsToSelector:modelSel]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id model = [cell performSelector:modelSel];
        #pragma clang diagnostic pop
        if (model && [model respondsToSelector:msgSel]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [model performSelector:msgSel];
            #pragma clang diagnostic pop
        }
    }
    
    // 尝试获取 msg
    SEL msgSel2 = NSSelectorFromString(@"msg");
    if ([cell respondsToSelector:msgSel2]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cell performSelector:msgSel2];
        #pragma clang diagnostic pop
    }
    
    return nil;
}

// ============================================================
// 功能1: 聊天消息左滑引用 / 右滑撤回
// ============================================================
%group DYYYIMSwipeActionsGroup

// Hook UIScrollView 来捕获滑动手势（UITableView 继承自 UIScrollView）
%hook UIScrollView

- (void)didMoveToWindow {
    %orig;
    
    // 检查功能开关
    if (!DYYYGetBoolWithDefault(@"DYYYEnableSwipeActions", NO)) return;
    
    // 检查是否在 IM 聊天页面
    UIViewController *vc = DYYYFindIMChatViewController(self);
    if (!vc) return;
    
    // 避免重复添加手势
    if (objc_getAssociatedObject(self, &kDYYYSwipeGestureKey)) return;
    objc_setAssociatedObject(self, &kDYYYSwipeGestureKey, @YES, OBJC_ASSOCIATION_RETAIN);
    
    NSLog(@"[DYYY-IM] Adding swipe gestures to %@", NSStringFromClass([self class]));
    
    // 添加滑动手势识别器
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(dyyy_handleLeftSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self addGestureRecognizer:leftSwipe];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
                                            initWithTarget:self
                                            action:@selector(dyyy_handleRightSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipe.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self addGestureRecognizer:rightSwipe];
}

%new
- (void)dyyy_handleLeftSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    if (!DYYYGetBoolWithDefault(@"DYYYEnableSwipeActions", NO)) return;
    
    // 默认启用引用功能
    NSString *leftAction = DYYYGetStringWithDefault(@"DYYYSwipeLeftAction", @"quote");
    if (![leftAction isEqualToString:@"quote"]) return;
    
    // 获取滑动位置的 Cell
    CGPoint location = [gesture locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:nil];
    
    // 向上查找 Cell
    UIView *cellView = hitView;
    while (cellView && ![cellView isKindOfClass:[UITableViewCell class]] && ![cellView isKindOfClass:[UICollectionViewCell class]]) {
        cellView = [cellView superview];
    }
    
    if (!cellView) {
        NSLog(@"[DYYY-IM] No cell found at swipe location");
        return;
    }
    
    id message = DYYYGetMessageFromCell(cellView);
    if (!message) {
        NSLog(@"[DYYY-IM] Cannot get message from cell");
        return;
    }
    
    NSLog(@"[DYYY-IM] Left swipe - quoting message");
    
    // 发送引用通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYQuoteMessage"
                                                        object:nil
                                                      userInfo:@{@"message": message,
                                                                @"cell": cellView}];
    
    [DYYYToast showSuccessToastWithMessage:@"已引用消息"];
}

%new
- (void)dyyy_handleRightSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    if (!DYYYGetBoolWithDefault(@"DYYYEnableSwipeActions", NO)) return;
    
    // 默认启用撤回功能
    NSString *rightAction = DYYYGetStringWithDefault(@"DYYYSwipeRightAction", @"recall");
    if (![rightAction isEqualToString:@"recall"]) return;
    
    // 获取滑动位置的 Cell
    CGPoint location = [gesture locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:nil];
    
    // 向上查找 Cell
    UIView *cellView = hitView;
    while (cellView && ![cellView isKindOfClass:[UITableViewCell class]] && ![cellView isKindOfClass:[UICollectionViewCell class]]) {
        cellView = [cellView superview];
    }
    
    if (!cellView) {
        NSLog(@"[DYYY-IM] No cell found at swipe location");
        return;
    }
    
    id message = DYYYGetMessageFromCell(cellView);
    if (!message) {
        NSLog(@"[DYYY-IM] Cannot get message from cell");
        return;
    }
    
    NSLog(@"[DYYY-IM] Right swipe - recalling message");
    
    // 发送撤回通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYRecallMessage"
                                                        object:nil
                                                      userInfo:@{@"message": message,
                                                                @"cell": cellView}];
    
    [DYYYToast showSuccessToastWithMessage:@"已撤回消息"];
}

// 手势识别委托方法 - 允许同时识别多个手势
%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

%new
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (!DYYYGetBoolWithDefault(@"DYYYEnableSwipeActions", NO)) return NO;
    
    // 检查是否在 IM 页面
    UIViewController *vc = DYYYFindIMChatViewController(self);
    return vc != nil;
}

%end

%end // DYYYIMSwipeActionsGroup


// ============================================================
// 功能2: 阻止已读回执上传
// ============================================================
%group DYYYBlockReadReceiptGroup

// 使用 %init 动态查找类
%ctor {
    // 在构造函数中动态查找并 Hook 类
}

%end // DYYYBlockReadReceiptGroup


// ============================================================
// 功能3: 阻止访客记录上传
// ============================================================
%group DYYYBlockVisitorUploadGroup

%end // DYYYBlockVisitorUploadGroup


// ============================================================
// 动态 Hook 阻止已读回执和访客上传的类
// ============================================================
%ctor {
    NSLog(@"[DYYY-IM] 正在初始化 IM 增强模块 v4...");
    
    // 初始化滑动手势功能
    %init(DYYYIMSwipeActionsGroup);
    
    // 动态查找并 Hook 已读回执相关类
    Class readReceiptClass = NSClassFromString(@"AWEIMReadReceiptDataCenter");
    if (readReceiptClass) {
        NSLog(@"[DYYY-IM] Found AWEIMReadReceiptDataCenter");
        %init(DYYYBlockReadReceiptGroup);
    } else {
        // 尝试其他可能的类名
        NSArray *possibleClasses = @[@"AWEIMReadReceiptManager",
                                      @"AWEIMMessageReadManager",
                                      @"AWEIMReadStatusManager"];
        for (NSString *className in possibleClasses) {
            Class cls = NSClassFromString(className);
            if (cls) {
                NSLog(@"[DYYY-IM] Found alternative read receipt class: %@", className);
                break;
            }
        }
    }
    
    // 动态查找并 Hook 访客上传相关类
    Class visitorClass = NSClassFromString(@"AWEProfileNavVisitorItemController");
    if (visitorClass) {
        NSLog(@"[DYYY-IM] Found AWEProfileNavVisitorItemController");
        %init(DYYYBlockVisitorUploadGroup);
    } else {
        NSArray *possibleClasses = @[@"AWEProfileVisitorController",
                                      @"AWEVisitorManager",
                                      @"AWEProfileVisitorManager"];
        for (NSString *className in possibleClasses) {
            Class cls = NSClassFromString(className);
            if (cls) {
                NSLog(@"[DYYY-IM] Found alternative visitor class: %@", className);
                break;
            }
        }
    }
    
    NSLog(@"[DYYY-IM] IM 增强模块初始化完成");
}
