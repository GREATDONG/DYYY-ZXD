//
//  DYYYCompat.h
//  DYYY
//
//  Swift Hook 安全兼容层
//

#ifndef DYYYCompat_h
#define DYYYCompat_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static inline Class DYYYGetClass(NSString *className) {
    if (!className || className.length == 0) {
        return nil;
    }
    return NSClassFromString(className);
}

static inline Class DYYYGetClassFromCandidates(NSArray<NSString *> *candidates) {
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
    NSLog(@"[DYYY] No class found from candidates");
    return nil;
}

#endif
