
//
//  DYYYSwiftHookManager.m
//  DYYY
//
//  Swift Hook 安全模式管理器实现
//

#import "DYYYSwiftHookManager.h"
#import &lt;objc/runtime.h&gt;

@interface DYYYSwiftHookManager ()
@property (nonatomic, strong) NSMutableSet&lt;NSString *&gt; *disabledFeatures;
@end

@implementation DYYYSwiftHookManager

+ (instancetype)sharedManager {
    static DYYYSwiftHookManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&amp;onceToken, ^{
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

- (BOOL)safeHookSwiftClass:(Class)targetClass
                  selector:(SEL)selector
               replacement:(id)replacement
              featureName:(NSString *)featureName {
    
    NSLog(@"[DYYY] SAFE MODE: Feature '%@' marked for hooking (disabled)", featureName);
    [self.disabledFeatures addObject:featureName];
    return NO;
}

- (BOOL)isFeatureAvailable:(NSString *)featureName {
    if (!featureName || featureName.length == 0) {
        return NO;
    }
    return ![self.disabledFeatures containsObject:featureName];
}

- (void)disableFeature:(NSString *)featureName {
    if (featureName &amp;&amp; featureName.length &gt; 0) {
        [self.disabledFeatures addObject:featureName];
        NSLog(@"[DYYY] SAFE MODE: Feature '%@' manually disabled.", featureName);
    }
}

- (NSSet&lt;NSString *&gt; *)disabledFeatures {
    return [self.disabledFeatures copy];
}

- (void)reset {
    [self.disabledFeatures removeAllObjects];
    NSLog(@"[DYYY] SAFE MODE: Manager reset complete.");
}

- (void)logStatus {
    NSLog(@"[DYYY] SAFE MODE: ====================");
    NSLog(@"[DYYY] SAFE MODE: Status Report");
    NSLog(@"[DYYY] SAFE MODE: ====================");
    NSLog(@"[DYYY] SAFE MODE: Disabled Features: %lu", (unsigned long)self.disabledFeatures.count);
    
    if (self.disabledFeatures.count &gt; 0) {
        for (NSString *feature in self.disabledFeatures) {
            NSLog(@"[DYYY] SAFE MODE:   - %@", feature);
        }
    }
    NSLog(@"[DYYY] SAFE MODE: ====================");
}

@end
