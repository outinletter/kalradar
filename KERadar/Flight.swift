import Foundation
import CoreLocation

struct Flight: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    var callsign: String?
    var number: String?
    var latitude: Double
    var longitude: Double
    var heading: Double?
    var altitude: Double?
    var speed: Double?
    var verticalSpeed: Double?
    var aircraft: String?
    var registration: String?
    var origin: String?
    var destination: String?
    var operatorCode: String?
    var timestamp: Date?
    var source: String?

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var label: String { number?.nonEmpty ?? callsign?.nonEmpty ?? id }
    var route: String { "\(origin?.nonEmpty ?? "출발 미상") → \(destination?.nonEmpty ?? "도착 미상")" }
    var observedUTC: String {
        guard let timestamp else { return "관측 시각 미상" }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(secondsFromGMT: 0); f.dateFormat = "HH:mm:ss 'UTC'"
        return f.string(from: timestamp)
    }
    var observationStatus: String {
        guard let timestamp else { return "관측 시각 미상" }
        let age = max(0, Date().timeIntervalSince(timestamp))
        return age > SharedRadar.staleAfterSeconds ? "오래된 위치 · \(Int(age / 60))분 전" : "최근 관측 · \(Int(age))초 전"
    }
    var briefing: String { "\(label) · \(route)\n고도 \(altitude.map { String(Int($0)) } ?? "미상") ft · 속도 \(speed.map { String(Int($0)) } ?? "미상") kt\n관측 \(observedUTC) · \(source ?? "출처 미상")\n등록 경로이며 실제 운항과 다를 수 있음 · 참고용" }
    var validPosition: Bool { latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude) }
    var isCallsignFallback: Bool { operatorCode?.nonEmpty == nil }
    var searchableText: String { [number, callsign, origin, destination, registration, aircraft].compactMap { $0 }.joined(separator: " ") }

    enum CodingKeys: String, CodingKey {
        case id = "fr24_id", callsign, number = "flight", latitude = "lat", longitude = "lon"
        case heading = "track", altitude = "alt", speed = "gspeed", verticalSpeed = "vspeed"
        case aircraft = "type", registration = "reg", origin = "orig_iata", destination = "dest_iata"
        case operatorCode = "operating_as", timestamp, source
    }
    init(id: String, callsign: String?, number: String?, latitude: Double, longitude: Double, heading: Double? = nil, altitude: Double? = nil, speed: Double? = nil, verticalSpeed: Double? = nil, aircraft: String? = nil, registration: String? = nil, origin: String? = nil, destination: String? = nil, operatorCode: String? = nil, timestamp: Date? = nil, source: String? = nil) {
        self.id = id; self.callsign = callsign; self.number = number; self.latitude = latitude; self.longitude = longitude
        self.heading = heading; self.altitude = altitude; self.speed = speed; self.verticalSpeed = verticalSpeed
        self.aircraft = aircraft; self.registration = registration; self.origin = origin; self.destination = destination
        self.operatorCode = operatorCode; self.timestamp = timestamp; self.source = source
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        callsign = try c.decodeIfPresent(String.self, forKey: .callsign)
        number = try c.decodeIfPresent(String.self, forKey: .number)
        latitude = try c.number(.latitude) ?? .nan; longitude = try c.number(.longitude) ?? .nan
        heading = try c.number(.heading); altitude = try c.number(.altitude); speed = try c.number(.speed); verticalSpeed = try c.number(.verticalSpeed)
        aircraft = try c.decodeIfPresent(String.self, forKey: .aircraft)
        registration = try c.decodeIfPresent(String.self, forKey: .registration)
        origin = try c.decodeIfPresent(String.self, forKey: .origin); destination = try c.decodeIfPresent(String.self, forKey: .destination)
        operatorCode = try c.decodeIfPresent(String.self, forKey: .operatorCode)
        source = try c.decodeIfPresent(String.self, forKey: .source)
        if let raw = try? c.decode(String.self, forKey: .timestamp) {
            let iso = ISO8601DateFormatter()
            timestamp = iso.date(from: raw)
            if timestamp == nil { iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; timestamp = iso.date(from: raw) }
        } else if let seconds = try c.number(.timestamp) { timestamp = Date(timeIntervalSince1970: seconds) }
        else { timestamp = nil }
    }
}

extension KeyedDecodingContainer where Key == Flight.CodingKeys {
    func number(_ key: Key) throws -> Double? {
        if !contains(key) { return nil }; if try decodeNil(forKey: key) { return nil }
        if let value = try? decode(Double.self, forKey: key) { return value }
        return Double(try decode(String.self, forKey: key))
    }
}
extension String {
    var nonEmpty: String? { let result = trimmingCharacters(in: .whitespacesAndNewlines); return result.isEmpty ? nil : result }
}

/// Explicit operating_as always wins. Flight number KE / painted_as KAL are NOT operator evidence.
enum KoreanAirFilter {
    static func includes(_ flight: Flight) -> Bool {
        guard flight.validPosition else { return false }
        if let operatorCode = flight.operatorCode?.nonEmpty { return operatorCode.uppercased() == "KAL" }
        guard let callsign = flight.callsign?.nonEmpty?.uppercased() else { return false }
        return callsign.range(of: SharedRadar.filterPattern, options: .regularExpression) != nil
    }
    static func apply(_ flights: [Flight]) -> [Flight] {
        var seen = Set<String>()
        return flights.filter { includes($0) && seen.insert($0.id).inserted }.sorted { $0.label < $1.label }
    }
}

struct LiveResponse: Decodable { let data: [Flight] }

enum DemoFlights {
    static let all = SharedRadar.demoFlights
}
