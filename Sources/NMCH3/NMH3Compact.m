#import "NMH3Compact.h"
#import "h3api.h"
#import <Foundation/Foundation.h>
#import <stdlib.h>

NSArray<NSNumber*>* NMH3Compact(NSArray<NSNumber*>* indexes) {
    if (indexes.count == 0) return @[];

    NSUInteger n = indexes.count;
    H3Index *in = (H3Index *)malloc(n * sizeof(H3Index));
    H3Index *out = (H3Index *)calloc(n, sizeof(H3Index));
    if (!in || !out) { free(in); free(out); return indexes; }

    for (NSUInteger i = 0; i < n; i++) {
        in[i] = indexes[i].unsignedLongLongValue;
    }

    H3Error err = compactCells(in, out, (int64_t)n);
    free(in);
    if (err != E_SUCCESS) { free(out); return indexes; }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:n];
    for (NSUInteger i = 0; i < n; i++) {
        if (out[i] != 0) {
            [result addObject:@(out[i])];
        }
    }
    free(out);
    return result;
}

NSArray<NSNumber*>* NMH3Uncompact(NSArray<NSNumber*>* indexes, NSInteger resolution) {
    if (indexes.count == 0) return @[];

    NSUInteger n = indexes.count;
    H3Index *in = (H3Index *)malloc(n * sizeof(H3Index));
    if (!in) return indexes;

    for (NSUInteger i = 0; i < n; i++) {
        in[i] = indexes[i].unsignedLongLongValue;
    }

    int64_t sz = 0;
    H3Error szErr = uncompactCellsSize(in, (int64_t)n, (int)resolution, &sz);
    if (szErr != E_SUCCESS || sz <= 0) { free(in); return indexes; }

    H3Index *out = (H3Index *)calloc((size_t)sz, sizeof(H3Index));
    if (!out) { free(in); return indexes; }

    H3Error err = uncompactCells(in, (int64_t)n, out, sz, (int)resolution);
    free(in);
    if (err != E_SUCCESS) { free(out); return indexes; }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)sz];
    for (int64_t i = 0; i < sz; i++) {
        if (out[i] != 0) {
            [result addObject:@(out[i])];
        }
    }
    free(out);
    return result;
}

H3Index NMH3ToParent(H3Index index, NSInteger resolution) {
    H3Index parent = 0;
    cellToParent(index, (int)resolution, &parent);
    return parent;
}

NSArray<NSNumber*>* NMH3ToChildren(H3Index index, NSInteger resolution) {
    int64_t sz = 0;
    H3Error szErr = cellToChildrenSize(index, (int)resolution, &sz);
    if (szErr != E_SUCCESS || sz <= 0) return @[@(index)];

    H3Index *buf = (H3Index *)calloc((size_t)sz, sizeof(H3Index));
    if (!buf) return @[@(index)];

    H3Error err = cellToChildren(index, (int)resolution, buf);
    if (err != E_SUCCESS) { free(buf); return @[@(index)]; }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)sz];
    for (int64_t i = 0; i < sz; i++) {
        if (buf[i] != 0) {
            [result addObject:@(buf[i])];
        }
    }
    free(buf);
    return result;
}

H3Index NMH3ToCenterChild(H3Index index, NSInteger resolution) {
    H3Index child = 0;
    cellToCenterChild(index, (int)resolution, &child);
    return child;
}
