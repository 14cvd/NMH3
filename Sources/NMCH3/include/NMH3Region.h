#pragma once
#import <Foundation/Foundation.h>
#import "NMH3Index.h"
NS_ASSUME_NONNULL_BEGIN
NSSet<NSNumber*>* NMH3KRing(H3Index origin, NSInteger k);
NSSet<NSNumber*>* NMH3HexRing(H3Index origin, NSInteger k);
NSArray<NSNumber*>* NMH3Polyfill(NSArray<NSValue*>* polygon, NSInteger resolution);
NSInteger NMH3Distance(H3Index from, H3Index to);
NSArray<NSNumber*>* NMH3Line(H3Index from, H3Index to);
NS_ASSUME_NONNULL_END
