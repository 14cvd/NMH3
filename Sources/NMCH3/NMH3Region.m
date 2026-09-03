#import "NMH3Region.h"
#import "NMH3Grid.h"
#import "h3api.h"
#import <Foundation/Foundation.h>
#import <stdlib.h>

NSSet<NSNumber*>* NMH3KRing(H3Index origin, NSInteger k) {
    int64_t sz = 0;
    maxGridDiskSize((int)k, &sz);
    H3Index *buf = (H3Index *)calloc((size_t)sz, sizeof(H3Index));
    if (!buf) return [NSSet setWithObject:@(origin)];

    gridDisk(origin, (int)k, buf);

    NSMutableSet *result = [NSMutableSet setWithCapacity:(NSUInteger)sz];
    for (int64_t i = 0; i < sz; i++) {
        // gridDisk fills unused slots with 0; skip them
        if (buf[i] != 0) {
            [result addObject:@(buf[i])];
        }
    }
    free(buf);
    return result;
}

NSSet<NSNumber*>* NMH3HexRing(H3Index origin, NSInteger k) {
    if (k == 0) return [NSSet setWithObject:@(origin)];

    // hexRing contains exactly 6*k cells for non-pentagon origins
    int64_t sz = 6 * k;
    H3Index *buf = (H3Index *)calloc((size_t)sz, sizeof(H3Index));
    if (!buf) return [NSSet set];

    H3Error err = gridRingUnsafe(origin, (int)k, buf);
    if (err != E_SUCCESS) {
        // Pentagon distortion: fall back to gridDisk minus inner disk
        free(buf);
        NSMutableSet *disk = (NSMutableSet *)NMH3KRing(origin, k).mutableCopy;
        NSSet *inner = NMH3KRing(origin, k - 1);
        [disk minusSet:inner];
        return disk;
    }

    NSMutableSet *result = [NSMutableSet setWithCapacity:(NSUInteger)sz];
    for (int64_t i = 0; i < sz; i++) {
        if (buf[i] != 0) {
            [result addObject:@(buf[i])];
        }
    }
    free(buf);
    return result;
}

NSArray<NSNumber*>* NMH3Polyfill(NSArray<NSValue*>* polygon, NSInteger resolution) {
    if (polygon.count == 0) return @[];

    // Build H3 GeoPolygon from the NSValue-wrapped NMGeoCoord vertices
    LatLng *verts = (LatLng *)malloc(polygon.count * sizeof(LatLng));
    if (!verts) return @[];

    for (NSUInteger i = 0; i < polygon.count; i++) {
        NMGeoCoord c = {0};
        [polygon[i] getValue:&c];
        verts[i].lat = degsToRads(c.lat);
        verts[i].lng = degsToRads(c.lng);
    }

    GeoLoop loop = { .numVerts = (int)polygon.count, .verts = verts };
    GeoPolygon geoPolygon = { .geoloop = loop, .numHoles = 0, .holes = NULL };

    int64_t sz = 0;
    H3Error sizeErr = maxPolygonToCellsSize(&geoPolygon, (int)resolution, 0, &sz);
    if (sizeErr != E_SUCCESS || sz <= 0) {
        free(verts);
        return @[];
    }

    H3Index *out = (H3Index *)calloc((size_t)sz, sizeof(H3Index));
    if (!out) { free(verts); return @[]; }

    polygonToCells(&geoPolygon, (int)resolution, 0, out);
    free(verts);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)sz];
    for (int64_t i = 0; i < sz; i++) {
        if (out[i] != 0) {
            [result addObject:@(out[i])];
        }
    }
    free(out);
    return result;
}

NSInteger NMH3Distance(H3Index from, H3Index to) {
    int64_t dist = 0;
    H3Error err = gridDistance(from, to, &dist);
    if (err != E_SUCCESS) return -1;
    return (NSInteger)dist;
}

NSArray<NSNumber*>* NMH3Line(H3Index from, H3Index to) {
    int64_t sz = 0;
    H3Error szErr = gridPathCellsSize(from, to, &sz);
    if (szErr != E_SUCCESS || sz <= 0) return @[@(from), @(to)];

    H3Index *buf = (H3Index *)calloc((size_t)sz, sizeof(H3Index));
    if (!buf) return @[@(from), @(to)];

    H3Error err = gridPathCells(from, to, buf);
    if (err != E_SUCCESS) {
        free(buf);
        return @[@(from), @(to)];
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)sz];
    for (int64_t i = 0; i < sz; i++) {
        [result addObject:@(buf[i])];
    }
    free(buf);
    return result;
}
