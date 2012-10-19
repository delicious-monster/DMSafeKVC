//
//  DMSafeKVC.m
//  Library
//
//  Created by Jonathon Mah on 2011-03-04.
//  Copyright 2011 Delicious Monster Software. All rights reserved.
//

#import "DMSafeKVC.h"

#import <objc/message.h>


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


NSSet *DMKeyPathsAffectingSuperclassOf(SEL valuesAffectingSel, Class targetClass)
{
    Class superclass = [targetClass superclass];
    if ([superclass respondsToSelector:valuesAffectingSel])
        return objc_msgSend(superclass, valuesAffectingSel) ? : [NSSet set];
    return [NSSet set];
}
