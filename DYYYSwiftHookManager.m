//
//  DYYYSwiftHookManager.m
//  DYYY
//
//  Swift Hook 安全模式管理器实现
//

#import "DYYYSwiftHookManager.h"
#import <objc/runtime.h>
#import <substrate.h>

@interface DYYYSwiftHookManager ()
@property (nonatomic, strong) NSMutableSet<NSString *> *failedFeatures;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *hookedMethods;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *successfulHooks;
@end

@implementation DYYYSwiftHookManager

+ (instancetype)sharedManager {
    static DYYYSwiftHookManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DYYYSwiftHookManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _failedFeatures = [NSMutableSet set];
        _hookedMethods = [NSMutableDictionary dictionary];
        _successfulHooks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)safeHookSwiftClass:(Class)targetClass
                  selector:(SEL)selector
               replacement:(id)replacement
              featureName:(NSString *)featureName {

    if (!featureName || featureName.length == 0) {
        NSLog(@"[DYYY] SAFE MODE: featureName is empty");
        return NO;
    }

    if (!targetClass) {
        NSLog(@"[DYYY] SAFE MODE: Class for feature '%@' not found. Disabling.", featureName);
        [self.failedFeatures addObject:featureName];
        return NO;
    }

    if (!selector) {
        NSLog(@"[DYYY] SAFE MODE: Selector for feature '%@' is nil. Disabling.", featureName);
        [self.failedFeatures addObject:featureName];
        return NO;
    }

    if (!replacement) {
        NSLog(@"[DYYY] SAFE MODE: Replacement block for feature '%@' is nil. Disabling.", featureName);
        [self.failedFeatures addObject:featureName];
        return NO;
    }

    Method method = class_getInstanceMethod(targetClass, selector);
    if (!method) {
        NSLog(@"[DYYY] SAFE MODE: Selector %@ for feature '%@' not found. Disabling.",
              NSStringFromSelector(selector), featureName);
        [self.failedFeatures addObject:featureName];
        return NO;
    }

    @try {
        IMP originalImp = method_getImplementation(method);
        IMP replacementImp = imp_implementationWithBlock(replacement);

        MSHookMessageEx(targetClass, selector, replacementImp, &originalImp);

        NSValue *key = [NSValue valueWithPointer:(__bridge void *)method];
        self.hookedMethods[featureName] = key;
        self.successfulHooks[featureName] = @YES;

        NSLog(@"[DYYY] SAFE MODE: Feature '%@' hooked successfully.", featureName);
        return YES;

    } @catch (NSException *exception) {
        NSLog(@"[DYYY] SAFE MODE: Exception while hooking '%@': %@. Disabling.",
              featureName, exception.reason);
        [self.failedFeatures addObject:featureName];
        return NO;
    }
}

- (BOOL)isFeatureAvailable:(NSString *)featureName {
    if (!featureName || featureName.length == 0) {
        return NO;
    }
    return ![self.failedFeatures containsObject:featureName];
}

- (void)disableFeature:(NSString *)featureName {
    if (featureName && featureName.length > 0) {
        [self.failedFeatures addObject:featureName];
        NSLog(@"[DYYY] SAFE MODE: Feature '%@' manually disabled.", featureName);
    }
}

- (NSSet<NSString *> *)failedFeatures {
    return [self.failedFeatures copy];
}

- (void)reset {
    [self.failedFeatures removeAllObjects];
    [self.hookedMethods removeAllObjects];
    [self.successfulHooks removeAllObjects];
    NSLog(@"[DYYY] SAFE MODE: Manager reset complete.");
}

- (void)logStatus {
    NSLog(@"[DYYY] SAFE MODE: ====================");
    NSLog(@"[DYYY] SAFE MODE: Status Report");
    NSLog(@"[DYYY] SAFE MODE: ====================");
    NSLog(@"[DYYY] SAFE MODE: Total Failed Features: %lu", (unsigned long)self.failedFeatures.count);
    NSLog(@"[DYYY] SAFE MODE: Total Successful Hooks: %lu", (unsigned long)self.successfulHooks.count);

    if (self.failedFeatures.count > 0) {
        NSLog(@"[DYYY] SAFE MODE: Failed Features:");
        for (NSString *feature in self.failedFeatures) {
            NSLog(@"[DYYY] SAFE MODE:   - %@", feature);
        }
    }

    if (self.successfulHooks.count > 0) {
        NSLog(@"[DYYY] SAFE MODE: Successful Hooks:");
        for (NSString *feature in self.successfulHooks) {
            NSLog(@"[DYYY] SAFE MODE:   + %@", feature);
        }
    }
    NSLog(@"[DYYY] SAFE MODE: ====================");
}

@end
