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
#define KVC5(a, b, c, d, e) \
    a, b, c, d, e; SAFE_KVC(a); SAFE_KVC(b); SAFE_KVC(c); SAFE_KVC(d); SAFE_KVC(e)
#define KVC6(a, b, c, d, e, f) \
    a, b, c, d, e, f; SAFE_KVC(a); SAFE_KVC(b); SAFE_KVC(c); SAFE_KVC(d); SAFE_KVC(e); SAFE_KVC(f)
#define KVC7(a, b, c, d, e, f, g) \
    a, b, c, d, e, f, g; SAFE_KVC(a); SAFE_KVC(b); SAFE_KVC(c); SAFE_KVC(d); SAFE_KVC(e); SAFE_KVC(f); SAFE_KVC(g)
#define KVC8(a, b, c, d, e, f, g, h) \
    a, b, c, d, e, f, g, h; SAFE_KVC(a); SAFE_KVC(b); SAFE_KVC(c); SAFE_KVC(d); SAFE_KVC(e); SAFE_KVC(f); SAFE_KVC(g); SAFE_KVC(h)

// Declares a specific safe-KVC-accessible key outside of a property
// Note that this will be expanded as returning "void *" for pointer properties
#define SAFE_KVC(NAME) \
    void NAME ## __KVCPath_(void)


// Common safe KVC defines
SAFE_KVC(/*id*/self); // NSObject
SAFE_KVC(/*id*/ selection); SAFE_KVC(/*NSArray*/ *selectedObjects); SAFE_KVC(/*id*/ content); // NSObjectController
SAFE_KVC(/*NSRect*/ bounds); // NSView
SAFE_KVC(/*id*/ objectValue); // NSControl
SAFE_KVC(/*NSString*/ *stringValue); // NSControl, NSNumber
SAFE_KVC(/*NSUInteger*/ count); // NSArray
SAFE_KVC(/*BOOL*/ isExecuting); SAFE_KVC(/*BOOL*/ isFinished); SAFE_KVC(/*BOOL*/ isReady); // NSOperation
SAFE_KVC(/*id*/ representedObject); // NSViewController
SAFE_KVC(/*id*/ arrangedObjects); SAFE_KVC(/*NSArray*/ *sortDescriptors); SAFE_KVC(/*NSUInteger*/ selectionIndex); SAFE_KVC(/*NSIndexSet*/ *selectionIndexes); // NSArrayController
SAFE_KVC(/*NSPrintingOrientation*/ orientation); SAFE_KVC(/*NSString*/ *paperName); SAFE_KVC(/*NSSize*/ paperSize); // NSPrintInfo


// Construct a checked key path string
#define KeyPath(...) \
    DMMakeKeyPath(__VA_ARGS__, nil)
#define K(x) \
    __builtin_choose_expr(sizeof(x ## __KVCPath_), @#x, @"_NOT_A_KEY_")


extern NSString *DMMakeKeyPath(NSString *firstKey, ...);
