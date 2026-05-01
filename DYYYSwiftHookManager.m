//
//  DYYYSwiftHookManager.m
//  DYYY
//

#import "DYYYSwiftHookManager.h"

@interface DYYYSwiftHookManager ()
@property (nonatomic, strong) NSMutableSet *disabledFeatures;
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
        _disabledFeatures = [NSMutableSet set];
    }
    return self;
}

- (BOOL)safeHookSwiftClass:(Class)targetClass selector:(SEL)selector replacement:(id)replacement featureName:(NSString *)featureName {
    [self.disabledFeatures addObject:featureName];
    return NO;
}

- (BOOL)isFeatureAvailable:(NSString *)featureName {
    return ![self.disabledFeatures containsObject:featureName];
}

- (void)disableFeature:(NSString *)featureName {
    if (featureName) {
        [self.disabledFeatures addObject:featureName];
    }
}

- (NSSet *)disabledFeatures {
    return [self.disabledFeatures copy];
}

- (void)reset {
    [self.disabledFeatures removeAllObjects];
}

- (void)logStatus {
    NSLog(@"DYYY SAFE MODE: %lu features disabled", (unsigned long)self.disabledFeatures.count);
}

@end
