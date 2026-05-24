#pragma once
#import <Foundation/Foundation.h>
#import "NMH3Index.h"
NS_ASSUME_NONNULL_BEGIN
typedef struct { double lat; double lng; } NMGeoCoord;
H3Index NMH3GeoToH3(double lat, double lng, NSInteger resolution);
NMGeoCoord NMH3ToGeo(H3Index index);
NSArray<NSValue*>* NMH3ToGeoBoundary(H3Index index);
double NMH3HexAreaKm2(NSInteger resolution);
double NMH3HexRadiusKm(NSInteger resolution);
double NMH3EdgeLengthKm(NSInteger resolution);
double NMH3HaversineDistanceKm(double lat1, double lng1, double lat2, double lng2);
NS_ASSUME_NONNULL_END
