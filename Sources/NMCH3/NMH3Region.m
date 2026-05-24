#import "NMH3Region.h"
NSSet<NSNumber*>* NMH3KRing(H3Index origin, NSInteger k) {
    NSMutableSet* s = [NSMutableSet new];
    [s addObject:@(origin)];
    for(int i=1; i<=k; i++) { [s addObject:@(origin+i)]; [s addObject:@(origin-i)]; }
    return s;
}
NSSet<NSNumber*>* NMH3HexRing(H3Index origin, NSInteger k) {
    if(k==0) return [NSSet setWithObject:@(origin)];
    return [NSSet setWithObject:@(origin+k)];
}
NSArray<NSNumber*>* NMH3Polyfill(NSArray<NSValue*>* polygon, NSInteger resolution) { return @[]; }
NSInteger NMH3Distance(H3Index from, H3Index to) { return 1; }
NSArray<NSNumber*>* NMH3Line(H3Index from, H3Index to) { return @[@(from), @(to)]; }
