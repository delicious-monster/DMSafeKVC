//
//  DMSafeKVC.h
//  Library
//
//  Created by Jonathon Mah on 2011-03-04.
//  Copyright 2011 Delicious Monster Software. All rights reserved.
//

#import <Foundation/Foundation.h>


// Declares a safe-KVC-accessible property
// Use as: @property (opts) MyType *_KVC(name);
#define _KVC(NAME) \
    NAME; SAFE_KVC(NAME)

// Declares a specific safe-KVC-accessible key outside of a property
#define SAFE_KVC(NAME) \
    void _DMSafeKVC__ ## NAME (void)


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
    __builtin_choose_expr(1, @#x, (NSString *)sizeof(_DMSafeKVC__ ## x))


extern NSString *DMMakeKeyPath(NSString *firstKey, ...);
