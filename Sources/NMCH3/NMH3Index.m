#import "NMH3Index.h"
BOOL NMH3IsValid(H3Index index) { return index != 0; }
NSInteger NMH3GetResolution(H3Index index) { return (index >> 52) & 0xF; }
NSInteger NMH3GetBaseCell(H3Index index) { return (index >> 45) & 0x7F; }
NSString* NMH3ToString(H3Index index) { return [NSString stringWithFormat:@"%llx", (unsigned long long)index]; }
H3Index NMH3FromString(NSString* str) {
    unsigned long long val = 0;
    [[NSScanner scannerWithString:str] scanHexLongLong:&val];
    return (H3Index)val;
}
BOOL NMH3IsPentagon(H3Index index) { return NO; }
