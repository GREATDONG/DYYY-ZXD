//
//  DYYYSwiftHooksSafe.m
//  DYYY
//

#import "DYYYSwiftHookManager.h"

@implementation DYYYSwiftHooksSafe

+ (void)setupAllSwiftHooks {
    [[DYYYSwiftHookManager sharedManager] logStatus];
}

@end
