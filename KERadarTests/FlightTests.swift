import XCTest
@testable import KERadar

final class FlightTests: XCTestCase {
    private func flight(operatorCode: String?, callsign: String? = "KAL123", number: String? = "KE123", lat: Double = 37) -> Flight {
        Flight(id: "test", callsign: callsign, number: number, latitude: lat, longitude: 127, operatorCode: operatorCode)
    }
    func testExplicitKALIncluded() { XCTAssertTrue(KoreanAirFilter.includes(flight(operatorCode: "KAL", callsign: "UNKNOWN"))) }
    func testCodeshareOtherOperatorExcluded() { XCTAssertFalse(KoreanAirFilter.includes(flight(operatorCode: "DAL", callsign: "KAL123", number: "KE123"))) }
    func testKEMarketingNumberInsufficient() { XCTAssertFalse(KoreanAirFilter.includes(flight(operatorCode: nil, callsign: "DAL123"))) }
    func testUnknownExcluded() { XCTAssertFalse(KoreanAirFilter.includes(flight(operatorCode: nil, callsign: nil))) }
    func testUnknownKALCallsignIncluded() { XCTAssertTrue(KoreanAirFilter.includes(flight(operatorCode: nil, callsign: " KAL123A "))); XCTAssertTrue(KoreanAirFilter.includes(flight(operatorCode: "", callsign: "kal123"))) }
    func testMalformedKALCallsignExcluded() { for value in ["KAL", "KALABC", "KAL123ZZ", "XKAL123", "KAL123OTHER"] { XCTAssertFalse(KoreanAirFilter.includes(flight(operatorCode: nil, callsign: value))) } }
    func testInvalidCoordinatesExcluded() { XCTAssertFalse(KoreanAirFilter.includes(flight(operatorCode: "KAL", lat: 91))); XCTAssertFalse(KoreanAirFilter.includes(flight(operatorCode: "KAL", lat: .nan))) }
    func testDuplicateIDsRemoved() { XCTAssertEqual(KoreanAirFilter.apply([flight(operatorCode: "KAL"), flight(operatorCode: "KAL")]).count, 1) }
    func testOfficialFullSchemaDecodes() throws {
        let json = #"{"data":[{"fr24_id":"321a0cc3","flight":"KE123","callsign":"KAL123","lat":37.4,"lon":126.4,"track":219,"alt":38000,"gspeed":500,"vspeed":340,"squawk":"6135","timestamp":"2023-11-08T10:10:00Z","source":"ADSB","hex":"394C19","type":"B789","reg":"HL-TEST","painted_as":"KAL","operating_as":"KAL","orig_iata":"ICN","orig_icao":"RKSI","dest_iata":"LHR","dest_icao":"EGLL","eta":"2023-11-08T16:12:24Z"}]}"#
        let item = try JSONDecoder().decode(LiveResponse.self, from: Data(json.utf8)).data[0]
        XCTAssertEqual(item.id, "321a0cc3"); XCTAssertEqual(item.registration, "HL-TEST"); XCTAssertEqual(item.altitude, 38000); XCTAssertEqual(item.speed, 500)
        XCTAssertEqual(item.operatorCode, "KAL"); XCTAssertEqual(item.origin, "ICN"); XCTAssertEqual(item.destination, "LHR"); XCTAssertNotNil(item.timestamp)
    }
    func testNullOptionalFieldsDecodes() throws {
        let json = #"{"data":[{"fr24_id":"null-test","lat":37,"lon":127,"callsign":null,"flight":null,"operating_as":null,"reg":null,"timestamp":null}]}"#
        let item = try JSONDecoder().decode(LiveResponse.self, from: Data(json.utf8)).data[0]
        XCTAssertNil(item.registration); XCTAssertNil(item.timestamp); XCTAssertFalse(KoreanAirFilter.includes(item))
    }
    func testFractionalTimestampAndNumericStrings() throws {
        let json = #"{"fr24_id":"test","lat":"37.5","lon":"127.2","timestamp":"2026-10-13T03:00:00.123Z"}"#
        let item = try JSONDecoder().decode(Flight.self, from: Data(json.utf8)); XCTAssertEqual(item.latitude, 37.5); XCTAssertNotNil(item.timestamp)
    }
    func testMalformedResponseRejected() { XCTAssertThrowsError(try JSONDecoder().decode(LiveResponse.self, from: Data(#"{"not_data":[]}"#.utf8))) }
    func testPublicProviderURLsUseHTTPS() {
        for provider in PublicADSBClient.Provider.allCases {
            XCTAssertEqual(provider.url.scheme, "https")
            XCTAssertNotNil(provider.url.host)
        }
        XCTAssertEqual(PublicADSBClient.Provider.sky.url.path, "/api/states/all")
    }
    func testDemoIsExplicitlyFictional() { XCTAssertEqual(DemoFlights.all.count, 8); XCTAssertTrue(DemoFlights.all.allSatisfy { $0.id.hasPrefix("demo-") && $0.registration?.hasPrefix("DEMO-") == true && $0.timestamp == nil }) }
}
