#pragma once
#import <Foundation/Foundation.h>
#import "NMH3Index.h"
NS_ASSUME_NONNULL_BEGIN
NSArray<NSNumber*>* NMH3Compact(NSArray<NSNumber*>* indexes);
NSArray<NSNumber*>* NMH3Uncompact(NSArray<NSNumber*>* indexes, NSInteger resolution);
H3Index NMH3ToParent(H3Index index, NSInteger resolution);
NSArray<NSNumber*>* NMH3ToChildren(H3Index index, NSInteger resolution);
H3Index NMH3ToCenterChild(H3Index index, NSInteger resolution);
NS_ASSUME_NONNULL_END
