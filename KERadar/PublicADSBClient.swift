import Foundation

actor PublicADSBClient {
    static let shared = PublicADSBClient()
    enum Provider: String, CaseIterable, Sendable {
        case sky = "OpenSky", lol = "ADSB.lol", fi = "adsb.fi"
        var url: URL { SharedRadar.providerURLs[rawValue]! }
    }
    struct Snapshot: Sendable { let flights: [Flight]; let provider: String; let notice: String?; let scope: String }
    enum Failure: LocalizedError {
        case unavailable(String)
        var errorDescription: String? { if case .unavailable(let text) = self { return text }; return nil }
    }
    private let session = URLSession(configuration: .ephemeral)
    private var cooldown: [Provider: Date] = [:]
    private var lastRequest: Date?
    private var busy = false
    func positions() async throws -> Snapshot {
        guard !busy else { throw Failure.unavailable("조회가 이미 진행 중입니다.") }
        if let lastRequest, Date().timeIntervalSince(lastRequest) < SharedRadar.refreshInterval { throw Failure.unavailable("공개 API 보호를 위해 조회 간격은 최소 30초입니다.") }
        busy = true; defer { busy = false }; lastRequest = Date()
        var failures: [String] = []
        for provider in Provider.allCases {
            try Task.checkCancellation()
            if let until = cooldown[provider], until > Date() { failures.append("\(provider.rawValue) 대기 중"); continue }
            var request = URLRequest(url: provider.url, timeoutInterval: 15)
            request.setValue("KERadar/1.1 (personal ADS-B viewer)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            do {
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else { throw Failure.unavailable("응답 형식 오류") }
                if http.statusCode == 429 {
                    let until = Self.retryDate(http, now: Date())
                    cooldown[provider] = until
                    failures.append("\(provider.rawValue) 사용 제한"); continue
                }
                guard http.statusCode == 200 else {
                    cooldown[provider] = Date().addingTimeInterval([401,403].contains(http.statusCode) ? 3600 : 120)
                    failures.append("\(provider.rawValue) HTTP \(http.statusCode)"); continue
                }
                let flights = try Self.decode(data, provider: provider)
                return Snapshot(flights: flights, provider: provider.rawValue, notice: failures.isEmpty ? nil : failures.joined(separator: " · ") + " → \(provider.rawValue)로 전환", scope: provider == .sky ? "전 세계 · 수신망 관측 범위" : "지역 대체 · 인천 중심 250해리")
            } catch {
                if Task.isCancelled { throw CancellationError() }
                cooldown[provider] = Date().addingTimeInterval(120)
                failures.append("\(provider.rawValue) 연결/데이터 오류")
            }
        }
        throw Failure.unavailable("모든 공개 API가 일시적으로 이용 불가합니다. " + failures.joined(separator: " · ") + ". 제한을 해제하거나 우회하지 않고 대기합니다.")
    }
    static func retryDate(_ response: HTTPURLResponse, now: Date) -> Date {
        if let raw = response.value(forHTTPHeaderField: "Retry-After") {
            if let seconds = Double(raw) { return now.addingTimeInterval(max(30, seconds)) }
            let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(secondsFromGMT: 0); f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
            if let date = f.date(from: raw) { return max(date, now.addingTimeInterval(30)) }
        }
        if let raw = response.value(forHTTPHeaderField: "X-Rate-Limit-Retry-After-Seconds"), let seconds = Double(raw) { return now.addingTimeInterval(max(30, seconds)) }
        return now.addingTimeInterval(3600)
    }
    static func decode(_ data: Data, provider: Provider) throws -> [Flight] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw Failure.unavailable("잘못된 응답") }
        func number(_ value: Any?) -> Double? { if value is NSNull { return nil }; if let n = value as? NSNumber { return n.doubleValue }; if let s = value as? String { return Double(s) }; return nil }
        var flights: [Flight] = []
        if provider == .sky {
            if root["states"] is NSNull { return [] }
            guard let rows = root["states"] as? [[Any]] else { throw Failure.unavailable("states 필드 없음") }
            for r in rows where r.count >= 12 {
                guard let hex = r[0] as? String, let callsign = r[1] as? String, let lon = number(r[5]), let lat = number(r[6]) else { continue }
                flights.append(Flight(id: hex, callsign: callsign, number: nil, latitude: lat, longitude: lon, heading: number(r[10]), altitude: number(r[7]).map { $0 * 3.28084 }, speed: number(r[9]).map { $0 * 1.943844 }, verticalSpeed: number(r[11]).map { $0 * 196.8504 }, timestamp: number(r[3]).map(Date.init(timeIntervalSince1970:)), source: provider.rawValue))
            }
        } else {
            guard let rows = (root["ac"] ?? root["aircraft"]) as? [[String: Any]] else { throw Failure.unavailable("aircraft 필드 없음") }
            if let message = root["msg"] as? String, message.lowercased() != "no error" { throw Failure.unavailable(message) }
            let now = number(root["now"]).map { $0 > 100000000000 ? $0 / 1000 : $0 } ?? Date().timeIntervalSince1970
            for r in rows {
                guard let hex = r["hex"] as? String, let callsign = r["flight"] as? String, let lat = number(r["lat"]), let lon = number(r["lon"]) else { continue }
                let age = number(r["seen_pos"])
                flights.append(Flight(id: hex, callsign: callsign, number: nil, latitude: lat, longitude: lon, heading: number(r["track"]), altitude: number(r["alt_baro"]), speed: number(r["gs"]), verticalSpeed: number(r["baro_rate"]), aircraft: r["t"] as? String, registration: r["r"] as? String, timestamp: age.map { Date(timeIntervalSince1970: now - $0) }, source: provider.rawValue))
            }
        }
        // Same circular scope for every provider; OpenSky's bounding box is trimmed locally.
        return KoreanAirFilter.apply(flights).filter { flight in
            if provider == .sky { return true }
            let radians = Double.pi / 180
            let a = pow(sin((flight.latitude - 37.46) * radians / 2), 2) + cos(37.46 * radians) * cos(flight.latitude * radians) * pow(sin((flight.longitude - 126.44) * radians / 2), 2)
            return 6371 * 2 * asin(sqrt(min(1, a))) <= 250 * 1.852
        }
    }
}
