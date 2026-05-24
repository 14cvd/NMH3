#import "NMH3Compact.h"
NSArray<NSNumber*>* NMH3Compact(NSArray<NSNumber*>* indexes) { return indexes; }
NSArray<NSNumber*>* NMH3Uncompact(NSArray<NSNumber*>* indexes, NSInteger resolution) { return indexes; }
H3Index NMH3ToParent(H3Index index, NSInteger resolution) { return index; }
NSArray<NSNumber*>* NMH3ToChildren(H3Index index, NSInteger resolution) { return @[@(index)]; }
H3Index NMH3ToCenterChild(H3Index index, NSInteger resolution) { return index; }
