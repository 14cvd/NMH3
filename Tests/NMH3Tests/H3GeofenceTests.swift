import XCTest
import CoreLocation
@testable import NMH3

@available(iOS 15.0, *)
final class H3GeofenceTests: XCTestCase {

    private let baku = CLLocationCoordinate2D(latitude: 40.4093, longitude: 49.8671)

    func testNearestTargetsOrdersByDistanceAndRespectsLimit() {
        let user = NMH3Kit.shared.cell(for: baku, resolution: .r9)
        // Targets spread north of the user, deliberately shuffled
        let targets = (1...30).map { step in
            NMH3Kit.shared.cell(
                for: CLLocationCoordinate2D(latitude: baku.latitude + Double(step) * 0.01, longitude: baku.longitude),
                resolution: .r9
            )
        }.shuffled()

        let nearest = NMH3GeofenceManager.nearestTargets(to: user, from: targets, limit: 20)

        XCTAssertEqual(nearest.count, 20)
        let distances = nearest.map { CLLocation(latitude: $0.center.latitude, longitude: $0.center.longitude)
            .distance(from: CLLocation(latitude: baku.latitude, longitude: baku.longitude)) }
        XCTAssertEqual(distances, distances.sorted(), "Targets must be ordered nearest first")
        XCTAssertLessThan(distances.last!, 21 * 1_200, "Only the 20 nearest targets (~1.1 km apart) may be chosen")
    }

    func testNearestTargetsWorksAcrossResolutions() {
        // User tracked at r9, store targets defined at r11 — gridDistance cannot compare these.
        let user = NMH3Kit.shared.cell(for: baku, resolution: .r9)
        let near = NMH3Kit.shared.cell(for: baku, resolution: .r11)
        let far = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 41.0, longitude: 49.8), resolution: .r11)

        let nearest = NMH3GeofenceManager.nearestTargets(to: user, from: [far, near], limit: 1)

        XCTAssertEqual(nearest, [near])
    }

    func testNearestTargetsWorksForFarAwayTargets() {
        // Targets on other continents: gridDistance fails here, so the old code dropped them all.
        let user = NMH3Kit.shared.cell(for: baku, resolution: .r9)
        let london = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), resolution: .r9)
        let sydney = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), resolution: .r9)

        let nearest = NMH3GeofenceManager.nearestTargets(to: user, from: [sydney, london], limit: 20)

        XCTAssertEqual(nearest, [london, sydney])
    }

    func testNearestTargetsHandlesEmptyInputAndZeroLimit() {
        let user = NMH3Kit.shared.cell(for: baku, resolution: .r9)
        XCTAssertTrue(NMH3GeofenceManager.nearestTargets(to: user, from: [], limit: 20).isEmpty)
        XCTAssertTrue(NMH3GeofenceManager.nearestTargets(to: user, from: [user], limit: 0).isEmpty)
    }
}
