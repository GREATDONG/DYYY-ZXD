//
//  DYYYSwiftHookManager.h
//  DYYY
//

#import <Foundation/Foundation.h>

@interface DYYYSwiftHookManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)safeHookSwiftClass:(Class)targetClass
                  selector:(SEL)selector
               replacement:(id)replacement
              featureName:(NSString *)featureName;

- (BOOL)isFeatureAvailable:(NSString *)featureName;

- (void)disableFeature:(NSString *)featureName;

- (NSSet *)disabledFeatures;

- (void)reset;

- (void)logStatus;

@end
