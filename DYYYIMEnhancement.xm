//
//  DYYYIMEnhancement.xm  (修复版 v5)
//  DYYY IM 聊天增强功能
//
//  实现方式：通过 Hook AWEIMCustomMenuComponent 在聊天长按菜单中注入功能
//  与现有表情下载功能使用完全相同的架构
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

// ============================================================
// 辅助函数：安全获取消息字符串属性
// ============================================================
static NSString *DYYYIMMsgStringValue(id object, NSString *selectorName) {
    if (!object || selectorName.length == 0) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (!selector || ![object respondsToSelector:selector]) return nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id value = [object performSelector:selector];
#pragma clang diagnostic pop
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    return nil;
}

// ============================================================
// 功能1: 聊天菜单注入 - 引用消息
// ============================================================
static AWEIMCustomMenuModel *DYYYIMCreateQuoteMenuItem(id cell) {
    if (!cell) return nil;
    
    __weak id weakCell = cell;
    AWEIMCustomMenuModel *menuItem = [%c(AWEIMCustomMenuModel) new];
    menuItem.title = @"引用消息";
    menuItem.imageName = @"im_chat_quote";
    menuItem.trackerName = @"引用消息";
    menuItem.willPerformMenuActionSelectorBlock = ^(id arg1) {
        id strongCell = weakCell;
        if (!strongCell) {
            [DYYYUtils showToast:@"无法获取消息"];
            return;
        }
        
        // 获取消息上下文
        AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)[strongCell valueForKey:@"currentContext"];
        if (!context) {
            [DYYYUtils showToast:@"无法获取消息上下文"];
            return;
        }
        
        id message = [context valueForKey:@"message"];
        if (!message) {
            [DYYYUtils showToast:@"无法获取消息对象"];
            return;
        }
        
        // 尝试获取消息文本内容
        NSString *textContent = DYYYIMMsgStringValue(message, @"textContent");
        if (textContent.length == 0) {
            textContent = DYYYIMMsgStringValue(message, @"text");
        }
        if (textContent.length == 0) {
            textContent = DYYYIMMsgStringValue(message, @"content");
        }
        
        if (textContent.length > 0) {
            // 将引用内容复制到剪贴板
            [[UIPasteboard generalPasteboard] setString:textContent];
            [DYYYUtils showToast:@"已复制消息内容（引用）"];
            NSLog(@"[DYYY-IM] 引用消息: %@", textContent);
        } else {
            // 非文本消息，获取消息ID用于引用
            NSString *msgId = DYYYIMMsgStringValue(message, @"messageId");
            if (msgId.length == 0) {
                msgId = DYYYIMMsgStringValue(message, @"msgId");
            }
            if (msgId.length > 0) {
                NSLog(@"[DYYY-IM] 引用非文本消息 ID: %@", msgId);
                [DYYYUtils showToast:@"已标记消息（非文本）"];
            } else {
                [DYYYUtils showToast:@"无法引用此消息"];
            }
        }
    };
    return menuItem;
}

// ============================================================
// 功能2: 聊天菜单注入 - 撤回消息
// ============================================================
static AWEIMCustomMenuModel *DYYYIMCreateRecallMenuItem(id cell) {
    if (!cell) return nil;
    
    __weak id weakCell = cell;
    AWEIMCustomMenuModel *menuItem = [%c(AWEIMCustomMenuModel) new];
    menuItem.title = @"撤回消息";
    menuItem.imageName = @"im_chat_recall";
    menuItem.trackerName = @"撤回消息";
    menuItem.willPerformMenuActionSelectorBlock = ^(id arg1) {
        id strongCell = weakCell;
        if (!strongCell) {
            [DYYYUtils showToast:@"无法获取消息"];
            return;
        }
        
        // 获取消息上下文
        AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)[strongCell valueForKey:@"currentContext"];
        if (!context) {
            [DYYYUtils showToast:@"无法获取消息上下文"];
            return;
        }
        
        id message = [context valueForKey:@"message"];
        if (!message) {
            [DYYYUtils showToast:@"无法获取消息对象"];
            return;
        }
        
        // 获取消息ID
        NSString *msgId = DYYYIMMsgStringValue(message, @"messageId");
        if (msgId.length == 0) {
            msgId = DYYYIMMsgStringValue(message, @"msgId");
        }
        
        // 获取消息发送者ID，判断是否是自己发的消息
        NSString *senderId = DYYYIMMsgStringValue(message, @"senderId");
        if (senderId.length == 0) {
            senderId = DYYYIMMsgStringValue(message, @"fromUid");
        }
        if (senderId.length == 0) {
            senderId = DYYYIMMsgStringValue(message, @"uid");
        }
        
        NSLog(@"[DYYY-IM] 尝试撤回消息 ID: %@, 发送者: %@", msgId, senderId);
        
        // 尝试通过消息对象调用撤回方法
        SEL recallSel = NSSelectorFromString(@"recallMessage");
        if ([message respondsToSelector:recallSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [message performSelector:recallSel];
#pragma clang diagnostic pop
            [DYYYUtils showToast:@"正在撤回消息..."];
            return;
        }
        
        // 尝试通过上下文调用撤回
        SEL contextRecallSel = NSSelectorFromString(@"recallMessage:");
        if ([context respondsToSelector:contextRecallSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [context performSelector:contextRecallSel withObject:message];
#pragma clang diagnostic pop
            [DYYYUtils showToast:@"正在撤回消息..."];
            return;
        }
        
        // 尝试通过通知触发撤回
        if (msgId.length > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYRecallMessage"
                                                                object:nil
                                                              userInfo:@{@"messageId": msgId}];
            [DYYYUtils showToast:@"已发送撤回请求"];
            NSLog(@"[DYYY-IM] 通过通知发送撤回请求: %@", msgId);
        } else {
            [DYYYUtils showToast:@"无法撤回此消息"];
            NSLog(@"[DYYY-IM] 无法获取消息ID，撤回失败");
        }
    };
    return menuItem;
}

// ============================================================
// 菜单项注入函数（核心）
// ============================================================
static NSArray *DYYYIMInjectMenuItems(NSArray *menuItems, id cell) {
    if (!menuItems || !cell) return menuItems;
    
    // 检查是否是 IM 聊天 Cell
    if (![cell isKindOfClass:%c(AWEIMReusableCommonCell)]) return menuItems;
    
    AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)[cell valueForKey:@"currentContext"];
    if (!context || ![context valueForKey:@"message"]) return menuItems;
    
    NSMutableArray *newMenuItems = [menuItems mutableCopy];
    BOOL enableSwipeActions = DYYYGetBool(@"DYYYEnableSwipeActions");
    
    // 注入引用消息选项
    if (enableSwipeActions) {
        BOOL hasQuote = NO;
        for (AWEIMCustomMenuModel *item in menuItems) {
            if ([item isKindOfClass:%c(AWEIMCustomMenuModel)] && [item.title isEqualToString:@"引用消息"]) {
                hasQuote = YES;
                break;
            }
        }
        if (!hasQuote) {
            AWEIMCustomMenuModel *quoteItem = DYYYIMCreateQuoteMenuItem(cell);
            if (quoteItem) {
                [newMenuItems addObject:quoteItem];
                NSLog(@"[DYYY-IM] 已注入引用消息菜单项");
            }
        }
    }
    
    // 注入撤回消息选项
    if (enableSwipeActions) {
        BOOL hasRecall = NO;
        for (AWEIMCustomMenuModel *item in menuItems) {
            if ([item isKindOfClass:%c(AWEIMCustomMenuModel)] && [item.title isEqualToString:@"撤回消息"]) {
                hasRecall = YES;
                break;
            }
        }
        if (!hasRecall) {
            AWEIMCustomMenuModel *recallItem = DYYYIMCreateRecallMenuItem(cell);
            if (recallItem) {
                [newMenuItems addObject:recallItem];
                NSLog(@"[DYYY-IM] 已注入撤回消息菜单项");
            }
        }
    }
    
    return newMenuItems ?: menuItems;
}


// ============================================================
// Group 1: 旧版签名
// ============================================================
%group DYYYIMEnhanceLegacyGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame tapLocationInScreen:(CGPoint)tapLocation menuItemList:(NSArray *)menuItems moreEmoticon:(BOOL)moreEmoticon onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMInjectMenuItems(menuItems, cell);
    %orig(bubbleFrame, tapLocation, updatedMenuItems, moreEmoticon, cell, extra);
}
%end
%end

// ============================================================
// Group 2: TapLocation 签名
// ============================================================
%group DYYYIMEnhanceTapLocationGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame tapLocationInScreen:(CGPoint)tapLocation menuItemList:(NSArray *)menuItems menuPanelOptions:(unsigned long long)menuPanelOptions moreEmoticon:(BOOL)moreEmoticon onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMInjectMenuItems(menuItems, cell);
    %orig(bubbleFrame, tapLocation, updatedMenuItems, menuPanelOptions, moreEmoticon, cell, extra);
}
%end
%end

// ============================================================
// Group 3: HighLow 签名
// ============================================================
%group DYYYIMEnhanceHighLowGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame highLocationInScreen:(CGPoint)highLocation lowLocationInScreen:(CGPoint)lowLocation tryHighLocationFirst:(BOOL)tryHighLocationFirst menuItemList:(NSArray *)menuItems menuPanelOptions:(unsigned long long)menuPanelOptions onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMInjectMenuItems(menuItems, cell);
    %orig(bubbleFrame, highLocation, lowLocation, tryHighLocationFirst, updatedMenuItems, menuPanelOptions, cell, extra);
}
%end
%end


// ============================================================
// 功能2: 阻止已读回执上传
// 使用 MSHookMessageEx 在运行时动态 Hook
// ============================================================
%group DYYYBlockReadReceiptGroup

%hook AWEIMReadReceiptDataCenter
- (void)reportReadReceipt:(id)receipt {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] 已阻止已读回执上报");
        return;
    }
    %orig;
}
- (void)ackRead:(id)message {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] 已阻止已读确认");
        return;
    }
    %orig;
}
- (void)sendReadReceipt:(id)receipt {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] 已阻止发送已读回执");
        return;
    }
    %orig;
}
%end

%end


// ============================================================
// 功能3: 阻止访客记录上传
// ============================================================
%group DYYYBlockVisitorUploadGroup

%hook AWEProfileNavVisitorItemController
- (void)reportVisit {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] 已阻止访客记录上报");
        return;
    }
    %orig;
}
- (void)didEnterVisitorsPage {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] 已阻止进入访客页面记录");
        return;
    }
    %orig;
}
%end

%end


// ============================================================
// 构造函数
// ============================================================
%ctor {
    NSLog(@"[DYYY-IM] 正在初始化 IM 增强模块 v5...");
    
    // 动态查找 AWEIMCustomMenuComponent 并初始化对应 group
    Class imMenuComponentClass = objc_getClass("AWEIMCustomMenuComponent");
    if (imMenuComponentClass) {
        SEL legacySelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:tapLocationInScreen:menuItemList:moreEmoticon:onCell:extra:");
        SEL tapLocationSelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:tapLocationInScreen:menuItemList:menuPanelOptions:moreEmoticon:onCell:extra:");
        SEL highLowSelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:highLocationInScreen:lowLocationInScreen:tryHighLocationFirst:menuItemList:menuPanelOptions:onCell:extra:");
        
        if (legacySelector && class_getInstanceMethod(imMenuComponentClass, legacySelector)) {
            %init(DYYYIMEnhanceLegacyGroup);
            NSLog(@"[DYYY-IM] 已初始化 Legacy 菜单组");
        }
        if (tapLocationSelector && class_getInstanceMethod(imMenuComponentClass, tapLocationSelector)) {
            %init(DYYYIMEnhanceTapLocationGroup);
            NSLog(@"[DYYY-IM] 已初始化 TapLocation 菜单组");
        }
        if (highLowSelector && class_getInstanceMethod(imMenuComponentClass, highLowSelector)) {
            %init(DYYYIMEnhanceHighLowGroup);
            NSLog(@"[DYYY-IM] 已初始化 HighLow 菜单组");
        }
    } else {
        NSLog(@"[DYYY-IM] 未找到 AWEIMCustomMenuComponent 类");
    }
    
    // 动态查找已读回执相关类
    Class readReceiptClass = objc_getClass("AWEIMReadReceiptDataCenter");
    if (readReceiptClass) {
        %init(DYYYBlockReadReceiptGroup);
        NSLog(@"[DYYY-IM] 已初始化阻止已读回执组");
    } else {
        NSLog(@"[DYYY-IM] 未找到 AWEIMReadReceiptDataCenter 类，阻止已读回执功能不可用");
    }
    
    // 动态查找访客记录相关类
    Class visitorClass = objc_getClass("AWEProfileNavVisitorItemController");
    if (visitorClass) {
        %init(DYYYBlockVisitorUploadGroup);
        NSLog(@"[DYYY-IM] 已初始化阻止访客上传组");
    } else {
        NSLog(@"[DYYY-IM] 未找到 AWEProfileNavVisitorItemController 类，阻止访客上传功能不可用");
    }
    
    NSLog(@"[DYYY-IM] IM 增强模块初始化完成");
}
