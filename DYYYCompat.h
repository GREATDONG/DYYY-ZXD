
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
static NSString *const DYYY_CLS_SWIFT_CommentCopy = @"";
static NSString *const DYYY_CLS_SWIFT_CommentSticker = @"";
static NSString *const DYYY_CLS_SWIFT_CommentSaveImage = @"";
static NSString *const DYYY_CLS_SWIFT_CommentHeaderGeneral = @"";
static NSString *const DYYY_CLS_SWIFT_CommentHeaderGoods = @"";
static NSString *const DYYY_CLS_SWIFT_CommentHeaderTemplate = @"";
static NSString *const DYYY_CLS_SWIFT_CommentBottomTips = @"";

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

#endif /* DYYYCompat_h */
