import XCTest
@testable import KERadar
final class PublicADSBTests: XCTestCase {
    func testADSBDecodingAndKALFilter() throws {
        let data = Data(#"{"now":1700000000000,"msg":"No error","ac":[{"hex":"abc123","flight":"KAL123 ","lat":37.5,"lon":126.5,"alt_baro":35000,"gs":450,"seen_pos":2,"r":"HL123","t":"B789"},{"hex":"def123","flight":"DAL123","lat":37.5,"lon":126.5}]}"#.utf8)
        let flights = try PublicADSBClient.decode(data, provider: .lol)
        XCTAssertEqual(flights.count, 1); XCTAssertEqual(flights[0].registration, "HL123")
        XCTAssertEqual(flights[0].timestamp?.timeIntervalSince1970, 1699999998)
    }
    func testOpenSkyConversionAndRadius() throws {
        let data = Data(#"{"states":[["abc123","KAL123","South Korea",1700000000,1700000001,126.5,37.5,10000,false,200,90,1],["def123","KAL456","South Korea",1700000000,1700000001,0,0,10000,false,200,90,1]]}"#.utf8)
        let flights = try PublicADSBClient.decode(data, provider: .sky)
        XCTAssertEqual(flights.count, 2); XCTAssertEqual(flights[0].altitude!, 32808.4, accuracy: 0.1)
        XCTAssertEqual(flights[0].speed!, 388.7688, accuracy: 0.1)
    }
    func testNullOpenSkyResultIsEmpty() throws { XCTAssertTrue(try PublicADSBClient.decode(Data(#"{"states":null}"#.utf8), provider: .sky).isEmpty) }
    func testMalformedNotTreatedAsEmpty() { XCTAssertThrowsError(try PublicADSBClient.decode(Data(#"{"error":"unavailable"}"#.utf8), provider: .fi)) }
    func testRateLimitHeaders() {
        let now = Date(timeIntervalSince1970: 1700000000)
        let r = HTTPURLResponse(url: PublicADSBClient.Provider.sky.url, statusCode: 429, httpVersion: nil, headerFields: ["X-Rate-Limit-Retry-After-Seconds":"86400"])!
        XCTAssertEqual(PublicADSBClient.retryDate(r, now: now), now.addingTimeInterval(86400))
        let r2 = HTTPURLResponse(url: PublicADSBClient.Provider.lol.url, statusCode: 429, httpVersion: nil, headerFields: ["Retry-After":"120"])!
        XCTAssertEqual(PublicADSBClient.retryDate(r2, now: now), now.addingTimeInterval(120))
    }
}
