import Foundation
actor RouteClient {
    static let shared = RouteClient()
    struct Route: Sendable { let origin: String?; let destination: String?; let number: String? }
    private var cache: [String: (Date, Route)] = [:]
    private var blockedUntil = Date.distantPast
    private let session = URLSession(configuration: .ephemeral)
    static func decode(_ data: Data, callsign: String) -> Route? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let response = root["response"] as? [String: Any], let route = response["flightroute"] as? [String: Any],
              Self.sameCallsign((route["callsign_icao"] as? String) ?? "", callsign) else { return nil }
        func airport(_ key: String) -> String? { let airport = route[key] as? [String: Any]; return (airport?["iata_code"] as? String)?.nonEmpty ?? (airport?["icao_code"] as? String)?.nonEmpty }
        return Route(origin: airport("origin"), destination: airport("destination"), number: (route["callsign_iata"] as? String)?.nonEmpty)
    }
    private static func sameCallsign(_ lhs: String, _ rhs: String) -> Bool {
        let normalize: (String) -> String = { value in
            let key = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard let range = key.range(of: "^KAL0*([0-9]+)([A-Z]?)$", options: .regularExpression) else { return key }
            let digits = key[range].replacingOccurrences(of: "^KAL0*", with: "KAL", options: .regularExpression)
            return digits
        }
        return normalize(lhs) == normalize(rhs)
    }
    private static func candidates(for key: String) -> [String] {
        guard let match = key.range(of: "^KAL0*([0-9]+)([A-Z]?)$", options: .regularExpression) else { return [key] }
        let suffix = String(key[match]).dropFirst(3)
        let digits = suffix.prefix { $0.isNumber }
        let tail = suffix.dropFirst(digits.count)
        let compact = String(Int(digits) ?? 0)
        let padded = String(format: "%04d", Int(compact) ?? 0)
        return Array(NSOrderedSet(array: [key, "KAL\(compact)\(tail)", "KAL\(padded)\(tail)"])).compactMap { $0 as? String }
    }
    func route(callsign: String) async -> Route? {
        let key = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard key.range(of: SharedRadar.filterPattern, options: .regularExpression) != nil else { return nil }
        if let (date, value) = cache[key], Date().timeIntervalSince(date) < 3600 { return value }
        guard Date() >= blockedUntil else { return nil }
        do {
            for candidate in Self.candidates(for: key) {
                guard let url = URL(string: SharedRadar.routeBaseURL + candidate) else { continue }
                let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 8))
            guard !Task.isCancelled, let http = response as? HTTPURLResponse else { return nil }
            if http.statusCode == 429 { blockedUntil = PublicADSBClient.retryDate(http, now: Date()); return nil }
                if http.statusCode == 404 { continue }
                guard http.statusCode == 200 else { continue }
                if let result = Self.decode(data, callsign: key) { cache[key] = (Date(), result); return result }
            }
            return nil
        } catch { return nil }
    }
}
