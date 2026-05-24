#import "NMH3Grid.h"
#import <math.h>
static const int NUM_FACES = 20;
static const int NUM_BASE_CELLS = 122;

H3Index NMH3GeoToH3(double lat, double lng, NSInteger resolution) {
    uint64_t r = (uint64_t)(resolution & 0xF) << 52;
    uint64_t latBits = (uint64_t)((lat + 90.0) * 10000.0) & 0xFFFFFF;
    uint64_t lngBits = (uint64_t)((lng + 180.0) * 10000.0) & 0xFFFFFF;
    return 0x0800000000000000ULL | r | (latBits << 24) | lngBits;
}

NMGeoCoord NMH3ToGeo(H3Index index) {
    uint64_t latBits = (index >> 24) & 0xFFFFFF;
    uint64_t lngBits = index & 0xFFFFFF;
    NMGeoCoord c;
    c.lat = (double)latBits / 10000.0 - 90.0;
    c.lng = (double)lngBits / 10000.0 - 180.0;
    return c;
}

NSArray<NSValue*>* NMH3ToGeoBoundary(H3Index index) {
    NMGeoCoord center = NMH3ToGeo(index);
    double r = NMH3HexRadiusKm(NMH3GetResolution(index)) / 111.0;
    NSMutableArray* arr = [NSMutableArray new];
    for (int i=0; i<6; i++) {
        double angle = 2.0 * M_PI * i / 6.0;
        NMGeoCoord pt;
        pt.lat = center.lat + r * sin(angle);
        pt.lng = center.lng + r * cos(angle);
        [arr addObject:[NSValue valueWithBytes:&pt objCType:@encode(NMGeoCoord)]];
    }
    return arr;
}

double NMH3HexAreaKm2(NSInteger res) { return 4.0 / pow(2.0, res); }
double NMH3HexRadiusKm(NSInteger res) { return sqrt(NMH3HexAreaKm2(res)); }
double NMH3EdgeLengthKm(NSInteger res) { return NMH3HexRadiusKm(res) * 0.9; }
double NMH3HaversineDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    double r = 6371.0;
    double dLat = (lat2 - lat1) * M_PI / 180.0;
    double dLng = (lng2 - lng1) * M_PI / 180.0;
    double a = sin(dLat/2)*sin(dLat/2) + cos(lat1*M_PI/180.0)*cos(lat2*M_PI/180.0)*sin(dLng/2)*sin(dLng/2);
    return r * 2 * atan2(sqrt(a), sqrt(1-a));
}
