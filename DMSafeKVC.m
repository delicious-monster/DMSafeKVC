//
//  DMSafeKVC.m
//  Library
//
//  Created by Jonathon Mah on 2011-03-04.
//  Copyright 2011 Delicious Monster Software. All rights reserved.
//

#import "DMSafeKVC.h"

#import <objc/message.h>


// ARC and MRR safe!
NSString *DMMakeKeyPath(NSString *firstKey, ...)
{
    NSMutableArray *keyArray = [NSMutableArray arrayWithObject:firstKey];
    va_list varargs;
    va_start(varargs, firstKey);
    NSString *nextKey = nil;
    while ((nextKey = va_arg(varargs, __unsafe_unretained NSString *)))
        [keyArray addObject:nextKey];
    va_end(varargs);
    return [keyArray componentsJoinedByString:@"."];
}


// ARC and MRR safe!
NSString *DMSplitKeyPath(NSString *keyPath, __autoreleasing NSString **remainingKeyPath)
{
    const NSRange firstPathSeparatorRange = [keyPath rangeOfString:@"." options:NSLiteralSearch];
    if (remainingKeyPath)
        *remainingKeyPath = (firstPathSeparatorRange.length ? [keyPath substringFromIndex:NSMaxRange(firstPathSeparatorRange)] : nil);
    return (firstPathSeparatorRange.length ? [keyPath substringToIndex:firstPathSeparatorRange.location] : keyPath);
}


// ARC and MRR safe!
NSSet *DMKeyPathsAffectingSuperclassOf(SEL valuesAffectingSel, Class targetClass, NSString *notSelfCheck)
{
    NSCAssert(![notSelfCheck isEqual:@"self"], @"KeysAffectingSuperclassOf() argument must be explicit class, not 'self', or subclasses will infinite-loop");
    Class superclass = [targetClass superclass];
    if ([superclass respondsToSelector:valuesAffectingSel])
        return objc_msgSend(superclass, valuesAffectingSel) ? : [NSSet set];
    return [NSSet set];
}


// ARC and MRR safe!
NSSet *DMOrphanedDependentKeyPathsForClass(Class targetClass) // doesn't check superclass
{
    static NSString *const dependentKeyPathSelectorPrefix = @"keyPathsForValuesAffecting";

    if (class_isMetaClass(targetClass))
        return nil;

    NSMutableSet *orphanedDependentKeyPathSelectorStrings = [NSMutableSet set];

    Class metaclass = object_getClass(targetClass);
    unsigned int classMethodCount;
    Method *classMethodArray = class_copyMethodList(metaclass, &classMethodCount); // doesn't include superclass methods

    for (NSUInteger i = 0; i < classMethodCount; i++) {
        Method method = classMethodArray[i];
        if (method_getNumberOfArguments(method) > 2) // expect only self, _cmd
            continue;
        NSString *dependentSelector = NSStringFromSelector(method_getName(method));
        if (dependentSelector.length <= dependentKeyPathSelectorPrefix.length || ![dependentSelector hasPrefix:dependentKeyPathSelectorPrefix])
            continue;
        NSString *capitalizedKeyName = [dependentSelector substringFromIndex:dependentKeyPathSelectorPrefix.length];
        if ([targetClass instancesRespondToSelector:NSSelectorFromString(capitalizedKeyName)])
            continue; // e.g. "keyPathsForValuesAffectingURL" can be satisfied by "URL".
        NSString *lowercaseKeyName = [[capitalizedKeyName substringToIndex:1].lowercaseString stringByAppendingString:[capitalizedKeyName substringFromIndex:1]];
        if ([targetClass instancesRespondToSelector:NSSelectorFromString(lowercaseKeyName)])
            continue; // e.g. "keyPathsForValuesAffectingFoo" can be satisfied by "foo"
        NSString *boolKeyName = [@"is" stringByAppendingString:capitalizedKeyName];
        if ([targetClass instancesRespondToSelector:NSSelectorFromString(boolKeyName)])
            continue; // e.g. "keyPathsForValuesAffectingFoo" can be satisfied by "isFoo"
        NSString *countOfKeyName = [@"countOf" stringByAppendingString:capitalizedKeyName];
        if ([targetClass instancesRespondToSelector:NSSelectorFromString(countOfKeyName)])
            continue; // e.g. "keyPathsForValuesAffectingFoo" can be satisfied by "countOfFoo" (indexed accessor - uncommon, so check this last)
        [orphanedDependentKeyPathSelectorStrings addObject:dependentSelector];
    }
    free(classMethodArray);
    return orphanedDependentKeyPathSelectorStrings;
}


#if __has_feature(objc_arc)
BOOL DMInstallOrphanedDependentKeyPathCheckOnNSObject()
{
    NSLog(@"%s unable to proceed; %s must be compiled with -fno-objc-arc", __func__, __FILE__);
    return NO;
}
#else
static BOOL checkOrphanedKeyPathsOnInitInstalled;
static dispatch_semaphore_t checkOrphanedKeyPathsOnInitMutex;
static NSMutableSet *checkOrphanedKeyPathsOnInitCheckedClasses;

@interface NSObject (DMSafeKVC)
- (id)init_DMSafeKVC_checkOrphanedKeyPaths;
@end
@interface NSResponder (DMSafeKVC)
- (id)initWithCoder_DMSafeKVC_checkOrphanedKeyPaths:(NSCoder *)decoder;
@end

BOOL DMInstallOrphanedDependentKeyPathCheckOnNSObject()
{
    if (checkOrphanedKeyPathsOnInitInstalled)
        return YES;

    NSLog(@"%s will check classes for orphaned dependent key paths on -init, hopefully this is a debug build!", __func__);

    Method originalInit = class_getInstanceMethod([NSObject class], @selector(init));
    Method replacementInit = class_getInstanceMethod([NSObject class], @selector(init_DMSafeKVC_checkOrphanedKeyPaths));
    if (!originalInit || !replacementInit)
        return NSLog(@"%s unable to proceed; -init and replacement must both be present", __func__), NO;

    Method originalNSResponderInitWithCoder = class_getInstanceMethod([NSResponder class], @selector(initWithCoder:));
    Method replacementNSResponderInitWithCoder = class_getInstanceMethod([NSResponder class], @selector(initWithCoder_DMSafeKVC_checkOrphanedKeyPaths:));
    if (originalNSResponderInitWithCoder && replacementNSResponderInitWithCoder)
        method_exchangeImplementations(originalNSResponderInitWithCoder, replacementNSResponderInitWithCoder);

    // Must initialize these before the first -init call otherwise we deadlock, because creaing an NSMutableSet itself calls -init
    checkOrphanedKeyPathsOnInitInstalled = YES;
    checkOrphanedKeyPathsOnInitMutex = dispatch_semaphore_create(1);
    checkOrphanedKeyPathsOnInitCheckedClasses = [[NSMutableSet alloc] init];

    method_exchangeImplementations(originalInit, replacementInit);
    return YES;
}

@implementation NSObject (DMSafeKVC)
- (id)init_DMSafeKVC_checkOrphanedKeyPaths;
{
    // If this is compiled with ARC, the compiler's retain/release/autoreleases cause crashes in some classes (NSTextView).

    if (!(self = [self init_DMSafeKVC_checkOrphanedKeyPaths])) // call original implementation
        return nil;

    for (Class ancestorClass = [self class]; (ancestorClass && ancestorClass != [NSObject class]); ancestorClass = class_getSuperclass(ancestorClass)) {
        dispatch_semaphore_wait(checkOrphanedKeyPathsOnInitMutex, DISPATCH_TIME_FOREVER);
        const BOOL classHasBeenChecked = [checkOrphanedKeyPathsOnInitCheckedClasses containsObject:ancestorClass];
        if (!classHasBeenChecked)
            [checkOrphanedKeyPathsOnInitCheckedClasses addObject:ancestorClass];
        dispatch_semaphore_signal(checkOrphanedKeyPathsOnInitMutex);

        if (classHasBeenChecked)
            break; // Once we've checked a class, we know we've checked its superclasses

        @autoreleasepool {
            for (NSString *orphanedDependentKeyPathSelector in DMOrphanedDependentKeyPathsForClass(ancestorClass))
                NSLog(@"*** WARNING: Class %@ implements +%@, but no matching accessor found", NSStringFromClass(ancestorClass), orphanedDependentKeyPathSelector);
        }
    }
    return self;
}
@end

@implementation NSResponder (DMSafeKVC)
- (id)initWithCoder_DMSafeKVC_checkOrphanedKeyPaths:(NSCoder *)decoder;
{
    // If this is compiled with ARC, the compiler's retain/release/autoreleases cause crashes in some classes (NSTextView).

    // Note: -[NSResponder initWithCoder:] does NOT call -[NSObject init]. It's a common case, so special-case it.
    if (!(self = [self initWithCoder_DMSafeKVC_checkOrphanedKeyPaths:decoder])) // call original implementation
        return nil;

    for (Class ancestorClass = [self class]; (ancestorClass && ancestorClass != [NSResponder class]); ancestorClass = class_getSuperclass(ancestorClass)) {
        dispatch_semaphore_wait(checkOrphanedKeyPathsOnInitMutex, DISPATCH_TIME_FOREVER);
        const BOOL classHasBeenChecked = [checkOrphanedKeyPathsOnInitCheckedClasses containsObject:ancestorClass];
        if (!classHasBeenChecked)
            [checkOrphanedKeyPathsOnInitCheckedClasses addObject:ancestorClass];
        dispatch_semaphore_signal(checkOrphanedKeyPathsOnInitMutex);

        if (classHasBeenChecked)
            break; // Once we've checked a class, we know we've checked its superclasses

        @autoreleasepool {
            for (NSString *orphanedDependentKeyPathSelector in DMOrphanedDependentKeyPathsForClass(ancestorClass))
                NSLog(@"*** WARNING: Class %@ implements +%@, but no matching accessor found", NSStringFromClass(ancestorClass), orphanedDependentKeyPathSelector);
        }
    }
    return self;
}
@end
#endif
