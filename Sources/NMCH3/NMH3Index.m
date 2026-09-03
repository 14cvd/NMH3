#import "NMH3Index.h"
#import "h3api.h"
#import <Foundation/Foundation.h>

BOOL NMH3IsValid(H3Index index) {
    return isValidCell(index) != 0;
}

NSInteger NMH3GetResolution(H3Index index) {
    return (NSInteger)getResolution(index);
}

NSInteger NMH3GetBaseCell(H3Index index) {
    return (NSInteger)getBaseCellNumber(index);
}

NSString* NMH3ToString(H3Index index) {
    char buf[17] = {0};
    h3ToString(index, buf, sizeof(buf));
    return [NSString stringWithUTF8String:buf];
}

H3Index NMH3FromString(NSString* str) {
    H3Index out = 0;
    stringToH3([str UTF8String], &out);
    return out;
}

/// Returns YES for the 12 pentagon base cells that exist at every resolution.
/// Pentagon cells require special handling in traversal and neighbor logic.
BOOL NMH3IsPentagon(H3Index index) {
    return isPentagon(index) != 0;
}
