//
//  DYYY.xm
//  DYYY - 主入口文件
//
//  模块化架构 v2.0
//  所有 Hooks 已拆分到独立模块
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// 导入模块
#import "DYYYSwiftHookManager.h"

// 声明外部模块初始化函数
extern void DYYYInitVideoHooks(void);
extern void DYYYInitCommentHooks(void);
extern void DYYYInitLiveHooks(void);
extern void DYYYInitUIHooks(void);
extern void DYYYInitSwiftHooks(void);

%ctor {
    NSLog(@"[DYYY] ========================================");
    NSLog(@"[DYYY] DYYY v2.0 模块化版本启动");
    NSLog(@"[DYYY] ========================================");
    
    // 初始化 Swift Hook 安全管理器
    [[DYYYSwiftHookManager sharedManager] reset];
    
    // 初始化各模块
    @try {
        NSLog(@"[DYYY] 初始化视频模块...");
        DYYYInitVideoHooks();
    } @catch (NSException *e) {
        NSLog(@"[DYYY] 视频模块初始化失败: %@", e);
    }
    
    @try {
        NSLog(@"[DYYY] 初始化评论模块...");
        DYYYInitCommentHooks();
    } @catch (NSException *e) {
        NSLog(@"[DYYY] 评论模块初始化失败: %@", e);
    }
    
    @try {
        NSLog(@"[DYYY] 初始化直播模块...");
        DYYYInitLiveHooks();
    } @catch (NSException *e) {
        NSLog(@"[DYYY] 直播模块初始化失败: %@", e);
    }
    
    @try {
        NSLog(@"[DYYY] 初始化界面模块...");
        DYYYInitUIHooks();
    } @catch (NSException *e) {
        NSLog(@"[DYYY] 界面模块初始化失败: %@", e);
    }
    
    @try {
        NSLog(@"[DYYY] 初始化 Swift Hook 安全模式...");
        DYYYInitSwiftHooks();
    } @catch (NSException *e) {
        NSLog(@"[DYYY] Swift Hook 初始化失败: %@", e);
    }
    
    // 打印状态
    [[DYYYSwiftHookManager sharedManager] logStatus];
    
    NSLog(@"[DYYY] ========================================");
    NSLog(@"[DYYY] 所有模块初始化完成");
    NSLog(@"[DYYY] ========================================");
}
