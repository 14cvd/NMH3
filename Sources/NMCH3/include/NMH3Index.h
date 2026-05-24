#pragma once
#import <Foundation/Foundation.h>
#include <stdint.h>
NS_ASSUME_NONNULL_BEGIN
typedef uint64_t H3Index;
BOOL NMH3IsValid(H3Index index) __attribute__((pure));
NSInteger NMH3GetResolution(H3Index index) __attribute__((pure));
NSInteger NMH3GetBaseCell(H3Index index) __attribute__((pure));
NSString* NMH3ToString(H3Index index);
H3Index NMH3FromString(NSString* str);
BOOL NMH3IsPentagon(H3Index index) __attribute__((pure));
NS_ASSUME_NONNULL_END
