import Foundation

enum APIError: LocalizedError, Equatable {
    case missingToken, authentication, credits, rateLimited(String?), http(Int), invalidResponse, decoding, network
    var errorDescription: String? {
        switch self {
        case .missingToken: return "API 토큰이 없습니다. 설정에서 공식 FR24 API 토큰을 저장하세요."
        case .authentication: return "인증에 실패했습니다 (401/403). 토큰과 API 접근 권한을 확인하세요."
        case .credits: return "API 크레딧이 부족하거나 구독이 필요합니다 (402). FR24 계정의 잔액을 확인하세요."
        case .rateLimited(let retry): return "요청 한도를 초과했습니다 (429). \(retry.map { "Retry-After: \($0). " } ?? "")잠시 후 수동으로 다시 시도하세요."
        case .http(let code): return "FR24 서버 오류 (\(code)). 잠시 후 다시 시도하세요."
        case .invalidResponse: return "유효하지 않은 서버 응답입니다."
        case .decoding: return "API 응답 형식을 읽을 수 없습니다. API 버전과 필드를 확인하세요."
        case .network: return "네트워크 연결을 확인하세요. 자동으로 재시도하지 않습니다."
        }
    }
}

struct FR24Client: Sendable {
    let session: URLSession
    init(session: URLSession = URLSession(configuration: .ephemeral)) { self.session = session }
    static func request(token: String) throws -> URLRequest {
        guard let clean = token.nonEmpty else { throw APIError.missingToken }
        var components = URLComponents(string: "https://fr24api.flightradar24.com/api/live/flight-positions/full")!
        components.queryItems = [URLQueryItem(name: "operating_as", value: "KAL")]
        var request = URLRequest(url: components.url!, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.setValue("Bearer \(clean)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
    func positions(token: String) async throws -> [Flight] {
        let request = try Self.request(token: token)
        let data: Data; let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch { if Task.isCancelled { throw CancellationError() }; throw APIError.network }
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200...299: break
        case 401, 403: throw APIError.authentication
        case 402: throw APIError.credits
        case 429: throw APIError.rateLimited(http.value(forHTTPHeaderField: "Retry-After"))
        default: throw APIError.http(http.statusCode)
        }
        do { return KoreanAirFilter.apply(try JSONDecoder().decode(LiveResponse.self, from: data).data) }
        catch { throw APIError.decoding }
    }
}
