
//
//  DYYYCompat.h
//  DYYY
//
//  Swift Hook 安全兼容层
//  提供类查找、方法查找等安全操作
//

#ifndef DYYYCompat_h
#define DYYYCompat_h

#import &lt;Foundation/Foundation.h&gt;
#import &lt;objc/runtime.h&gt;

// Swift 类名常量（真实类名可能不同）
static NSString *const DYYY_CLS_COMMENT_COPY = @"";
static NSString *const DYYY_CLS_COMMENT_LIKE = @"";
static NSString *const DYYY_CLS_COMMENT_SHARE = @"";
static NSString *const DYYY_CLS_COMMENT_REPORT = @"";
static NSString *const DYYY_CLS_COMMENT_DELETE = @"";
static NSString *const DYYY_CLS_COMMENT_EDIT = @"";
static NSString *const DYYY_CLS_COMMENT_REPLY = @"";

// 安全获取 Class
static inline Class DYYYGetClass(NSString *className) {
    if (!className || className.length == 0) {
        return nil;
    }
    Class cls = NSClassFromString(className);
    return cls;
}

// 从候选列表中找到存在的 Class
static inline Class DYYYGetClassFromCandidates(NSArray&lt;NSString *&gt; *candidates) {
    if (!candidates || candidates.count == 0) {
        return nil;
    }
    for (NSString *className in candidates) {
        Class cls = NSClassFromString(className);
        if (cls) {
            NSLog(@"[DYYY] Found class from candidates: %@", className);
            return cls;
        }
    }
    NSLog(@"[DYYY] No class found from candidates: %@", candidates);
    return nil;
}

// 安全获取 Method
static inline Method DYYYGetMethod(Class cls, SEL sel, BOOL isInstanceMethod) {
    if (!cls || !sel) {
        return nil;
    }
    Method m = nil;
    if (isInstanceMethod) {
        m = class_getInstanceMethod(cls, sel);
    } else {
        m = class_getClassMethod(cls, sel);
    }
    return m;
}

// 安全 Hook 函数
static inline BOOL DYYYHook(Class cls, SEL sel, IMP newImp, IMP *origImp) {
    if (!cls || !sel || !newImp) {
        NSLog(@"[DYYY] Hook failed: invalid parameters");
        return NO;
    }
    
    // 先尝试获取原有实现
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        if (origImp) {
            *origImp = method_setImplementation(m, newImp);
        } else {
            method_setImplementation(m, newImp);
        }
        NSLog(@"[DYYY] Hooked method: %@ on class: %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return YES;
    }
    
    NSLog(@"[DYYY] Hook failed: method %@ not found on class %@", NSStringFromSelector(sel), NSStringFromClass(cls));
    return NO;
}

#endif /* DYYYCompat_h */
