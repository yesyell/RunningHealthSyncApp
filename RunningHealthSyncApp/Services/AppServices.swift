import Foundation

struct AppConfiguration {
    let baseURL: URL

    init(baseURL: URL = AppConfiguration.defaultBaseURL) {
        self.baseURL = baseURL
    }

    private static var defaultBaseURL: URL {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "RunningHealthBaseURL") as? String,
           let url = URL(string: configured),
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return url
        }
        return URL(string: "https://runnershello.duckdns.org")!
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let body: Encodable?

    init(path: String, method: HTTPMethod = .get, body: Encodable? = nil) {
        self.path = path
        self.method = method
        self.body = body
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "서버 응답을 해석하지 못했습니다."
        case let .server(message):
            return message
        }
    }
}

final class AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

final class HTTPClient {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, baseURL: URL) async throws -> Response {
        let normalizedPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var request = URLRequest(url: baseURL.appendingPathComponent(normalizedPath))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainSessionStore.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if http.statusCode == 401 {
            KeychainSessionStore.shared.clear()
            throw APIError.server("세션이 만료되었습니다. 다시 로그인해 주세요.")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            if let errorPayload = try? decoder.decode([String: String].self, from: data),
               let message = errorPayload["error"] {
                throw APIError.server(message)
            }
            if let errorPayload = try? decoder.decode([String: String].self, from: data),
               let message = errorPayload["detail"] {
                throw APIError.server(message)
            }
            throw APIError.server("서버 호출에 실패했습니다. status=\(http.statusCode)")
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        return try decoder.decode(Response.self, from: data)
    }
}

struct EmptyResponse: Decodable {}

protocol RunningHealthServiceProviding {
    var baseURLDisplayString: String { get }
    func fetchToolCatalog() async throws -> [ToolDefinition]
    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse
    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse
    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse
    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse
    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse
    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse
}

final class RunningHealthAPIService: RunningHealthServiceProviding {
    private let configuration: AppConfiguration
    private let client: HTTPClient

    init(configuration: AppConfiguration, client: HTTPClient = HTTPClient()) {
        self.configuration = configuration
        self.client = client
    }

    var baseURLDisplayString: String {
        configuration.baseURL.absoluteString
    }

    func fetchToolCatalog() async throws -> [ToolDefinition] {
        let response: ToolCatalogResponse = try await client.send(Endpoint(path: "/api/tools"), baseURL: configuration.baseURL)
        return response.tools
    }

    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse {
        let body = DashboardRequest(location: location, lat: lat, lon: lon)
        return try await client.send(Endpoint(path: "/api/dashboard", method: .post, body: body), baseURL: configuration.baseURL)
    }

    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse {
        try await client.send(
            Endpoint(path: "/api/natural-query", method: .post, body: NaturalQueryRequest(query: query)),
            baseURL: configuration.baseURL
        )
    }

    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse {
        try await callTool(name: "health_report", arguments: [
            "period": .string(period),
            "n": .integer(n),
        ])
    }

    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse {
        try await callTool(name: "health_insight", arguments: [
            "metric": .string(metric),
            "weeks": .integer(weeks),
        ])
    }

    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse {
        var args: [String: JSONValue] = [:]
        if let location, !location.isEmpty {
            args["location"] = .string(location)
        }
        if let lat {
            args["lat"] = .number(lat)
        }
        if let lon {
            args["lon"] = .number(lon)
        }
        return try await callTool(name: "running_recommend", arguments: args)
    }

    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse {
        let sql = Self.buildSQL(metric: metric, period: period, limit: limit)
        return try await callTool(name: "health_query", arguments: [
            "sql": .string(sql),
        ])
    }

    private func callTool<Response: Decodable>(name: String, arguments: [String: JSONValue]) async throws -> Response {
        return try await client.send(
            Endpoint(path: "/api/call/\(name)", method: .post, body: arguments),
            baseURL: configuration.baseURL
        )
    }

    private static func buildSQL(metric: String, period: String, limit: Int) -> String {
        let safeLimit = min(max(limit, 1), 100)
        if period == "monthly" {
            return """
            SELECT
              STRFTIME('%Y-%m-01', rs.session_date) AS month_start,
              COUNT(*) AS session_count,
              ROUND(SUM(rs.distance_km), 2) AS total_km,
              ROUND(AVG(p.pace_min_per_km), 2) AS avg_pace,
              ROUND(AVG(rs.avg_hr), 1) AS avg_bpm
            FROM running_sessions rs
            LEFT JOIN v_running_pace p ON p.session_id = rs.id
            WHERE rs.user_id = :user_id
            GROUP BY month_start
            ORDER BY month_start DESC
            LIMIT \(safeLimit)
            """
        }
        if period == "recent_sessions" {
            return """
            SELECT
              session_date,
              id AS session_id,
              distance_km,
              duration_min,
              avg_pace_min_km AS pace_min_per_km,
              avg_hr AS avg_bpm
            FROM running_sessions
            WHERE user_id = :user_id
            ORDER BY started_at DESC
            LIMIT \(safeLimit)
            """
        }
        if metric == "pace" {
            return """
            SELECT session_date, pace_min_per_km, moving_km
            FROM v_running_pace
            WHERE user_id = :user_id
            ORDER BY session_date DESC
            LIMIT \(safeLimit)
            """
        }
        if metric == "heart_rate" {
            return """
            SELECT
              DATE(session_date, 'weekday 1', '-7 days') AS week_start,
              ROUND(AVG(avg_hr), 1) AS avg_bpm,
              COUNT(*) AS session_count
            FROM running_sessions
            WHERE user_id = :user_id
            GROUP BY week_start
            ORDER BY week_start DESC
            LIMIT \(safeLimit)
            """
        }
        return """
        SELECT week_start, session_count, total_km, avg_pace
        FROM v_weekly_summary
        WHERE user_id = :user_id
        ORDER BY week_start DESC
        LIMIT \(safeLimit)
        """
    }
}

struct DashboardRequest: Encodable {
    let location: String?
    let lat: Double?
    let lon: Double?
}

struct NaturalQueryRequest: Encodable {
    let query: String
}

final class PreviewRunningHealthService: RunningHealthServiceProviding {
    static let shared = PreviewRunningHealthService()

    var baseURLDisplayString: String {
        "preview://running-health"
    }

    func fetchToolCatalog() async throws -> [ToolDefinition] {
        PreviewData.toolDefinitions
    }

    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse {
        PreviewData.dashboard
    }

    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse {
        PreviewData.naturalLanguage(query: query)
    }

    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse {
        PreviewData.report(period: period)
    }

    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse {
        PreviewData.insight(metric: metric)
    }

    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse {
        PreviewData.recommendation
    }

    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse {
        PreviewData.query(metric: metric, period: period)
    }
}
