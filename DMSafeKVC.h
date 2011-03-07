//
//  DMSafeKVC.h
//  Library
//
//  Created by Jonathon Mah on 2011-03-04.
//  Copyright 2011 Delicious Monster Software. All rights reserved.
//

#import <Foundation/Foundation.h>


// Declares a safe-KVC-accessible property
// Use as: @property (opts) MyType KVC(*name);
// Use as: @property (opts) MyType KVC2(*firstName, *lastName);
#define KVC(a) \
    a; SAFE_KVC(a)
#define KVC2(a, b) \
    a, b; SAFE_KVC(a); SAFE_KVC(b)
#define KVC3(a, b, c) \
    a, b, c; SAFE_KVC(a); SAFE_KVC(b); SAFE_KVC(c)
#define KVC4(a, b, c, d) \
    a, b, c, d; SAFE_KVC(a); SAFE_KVC(b); SAFE_KVC(c); SAFE_KVC(d)

// Declares a specific safe-KVC-accessible key outside of a property
// Note that this will be expanded as returning "void *" for pointer properties
#define SAFE_KVC(NAME) \
    void NAME ## __KVCPath_(void)


// Common safe KVC defines
SAFE_KVC(self);
SAFE_KVC(selection);
SAFE_KVC(content);
SAFE_KVC(length);
SAFE_KVC(count);
SAFE_KVC(sortDescriptors);
SAFE_KVC(arrangedObjects);
SAFE_KVC(selectedObjects);
SAFE_KVC(selectionIndex);
SAFE_KVC(selectionIndexes);


// Construct a checked key path string
#define KeyPath(...) \
    DMMakeKeyPath(__VA_ARGS__, nil)
#define K(x) \
    __builtin_choose_expr(1, @#x, (NSString *)sizeof(x ## __KVCPath_))


extern NSString *DMMakeKeyPath(NSString *firstKey, ...);
