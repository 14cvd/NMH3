#import "NMH3Grid.h"
#import "h3api.h"
#import <math.h>

H3Index NMH3GeoToH3(double lat, double lng, NSInteger resolution) {
    LatLng coord = { .lat = degsToRads(lat), .lng = degsToRads(lng) };
    H3Index out = 0;
    latLngToCell(&coord, (int)resolution, &out);
    return out;
}

NMGeoCoord NMH3ToGeo(H3Index index) {
    LatLng coord = {0};
    cellToLatLng(index, &coord);
    NMGeoCoord c;
    c.lat = radsToDegs(coord.lat);
    c.lng = radsToDegs(coord.lng);
    return c;
}

NSArray<NSValue*>* NMH3ToGeoBoundary(H3Index index) {
    CellBoundary boundary = {0};
    cellToBoundary(index, &boundary);
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:boundary.numVerts];
    for (int i = 0; i < boundary.numVerts; i++) {
        NMGeoCoord pt;
        pt.lat = radsToDegs(boundary.verts[i].lat);
        pt.lng = radsToDegs(boundary.verts[i].lng);
        [arr addObject:[NSValue valueWithBytes:&pt objCType:@encode(NMGeoCoord)]];
    }
    return arr;
}

double NMH3HexAreaKm2(NSInteger res) {
    double out = 0.0;
    getHexagonAreaAvgKm2((int)res, &out);
    return out;
}

double NMH3HexRadiusKm(NSInteger res) {
    // Radius is derived from area: area of regular hexagon = (3√3/2)r²
    // So r = sqrt(area * 2 / (3√3))
    double areKm2 = NMH3HexAreaKm2(res);
    return sqrt(areKm2 * 2.0 / (3.0 * sqrt(3.0)));
}

double NMH3EdgeLengthKm(NSInteger res) {
    double out = 0.0;
    getHexagonEdgeLengthAvgKm((int)res, &out);
    return out;
}

double NMH3HaversineDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    LatLng a = { .lat = degsToRads(lat1), .lng = degsToRads(lng1) };
    LatLng b = { .lat = degsToRads(lat2), .lng = degsToRads(lng2) };
    return greatCircleDistanceKm(&a, &b);
}
