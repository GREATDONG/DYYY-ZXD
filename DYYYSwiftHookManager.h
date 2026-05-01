//
//  DYYYSwiftHookManager.h
//  DYYY
//
//  Swift Hook 安全模式管理器
//  核心功能：优雅降级、零崩溃、功能监控
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYYYSwiftHookManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)safeHookSwiftClass:(Class)targetClass
                  selector:(SEL)selector
               replacement:(id)replacement
              featureName:(NSString *)featureName;

- (BOOL)isFeatureAvailable:(NSString *)featureName;

- (void)disableFeature:(NSString *)featureName;

- (NSSet<NSString *> *)failedFeatures;

- (void)reset;

- (void)logStatus;

@end

NS_ASSUME_NONNULL_END
