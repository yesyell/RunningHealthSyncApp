import Foundation

enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case integer(Int)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .integer(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    var stringValue: String? {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return String(value)
        case let .integer(value):
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        default:
            return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case let .number(value):
            return value
        case let .integer(value):
            return Double(value)
        case let .string(value):
            return Double(value)
        default:
            return nil
        }
    }

    var arrayValue: [JSONValue]? {
        if case let .array(value) = self {
            return value
        }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case let .object(value) = self {
            return value
        }
        return nil
    }

    func prettyPrinted(indentation: Int = 0) -> String {
        let padding = String(repeating: " ", count: indentation)
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return String(format: "%.3f", value)
        case let .integer(value):
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        case let .array(values):
            return values.map { "\($0.prettyPrinted(indentation: indentation + 2))" }.joined(separator: "\n")
        case let .object(dictionary):
            return dictionary.keys.sorted().map { key in
                let value = dictionary[key] ?? .null
                return "\(padding)\(key): \(value.prettyPrinted(indentation: indentation + 2))"
            }.joined(separator: "\n")
        case .null:
            return "null"
        }
    }
}

struct UserProfile: Codable {
    let name: String
    let age: Int
    let runningGoal: String
    let targetPaceMinKm: Double
    let targetPaceDisplay: String
    let weeklyTargetKm: Double
    let preferredDistanceKm: [Double]
    let preferredArea: String
    let restingHeartRate: Int
    let maxHeartRate: Int
    let fitnessLevel: String
    let notes: String
}

struct ToolDefinition: Codable, Identifiable {
    let name: String
    let description: String
    let inputSchema: JSONValue

    var id: String { name }
}

struct ToolCatalogResponse: Codable {
    let tools: [ToolDefinition]
}

struct ToolCallRequest: Encodable {
    let name: String
    let arguments: [String: JSONValue]
}

struct ToolCallEnvelope<Response: Decodable>: Decodable {
    let tool: String
    let arguments: [String: JSONValue]
    let result: Response
}

struct DashboardResponse: Codable {
    let userProfile: UserProfile
    let weeklyReport: HealthReportResponse
    let paceInsight: HealthInsightResponse
    let recoveryInsight: HealthInsightResponse
    let recommendation: RunningRecommendResponse
}

struct WeeklySeriesPoint: Codable, Identifiable {
    let weekStart: String
    let sessionCount: Int?
    let totalKm: Double?
    let avgPace: Double?

    var id: String { weekStart }
}

struct MonthlySeriesPoint: Codable, Identifiable {
    let monthStart: String
    let sessionCount: Int?
    let totalKm: Double?
    let avgPace: Double?

    var id: String { monthStart }
}

struct ReportSummary: Codable {
    let totalKm: Double
    let avgPaceOverall: Double?
    let userGoal: String
    let weeklyTargetKm: Double
    let targetPaceMinKm: Double
}

struct HealthReportResponse: Codable {
    let period: String
    let series: [ReportSeriesPoint]
    let summary: ReportSummary
    let error: String?
}

struct ReportSeriesPoint: Codable, Identifiable {
    let weekStart: String?
    let monthStart: String?
    let sessionCount: Int?
    let totalKm: Double?
    let avgPace: Double?

    var id: String { weekStart ?? monthStart ?? UUID().uuidString }
    var label: String { weekStart ?? monthStart ?? "-" }
}

struct QueryDescriptor: Codable {
    let mode: String
    let metric: String?
    let period: String?
    let limit: Int?
}

struct QueryContext: Codable {
    let userTargetPace: Double?
    let userGoal: String?
    let weeklyTargetKm: Double?
    let preferredDistanceKm: [Double]?
    let rowCount: Int
}

struct StructuredMetricRow: Codable, Identifiable {
    let weekStart: String?
    let monthStart: String?
    let sessionDate: String?
    let sessionId: Int?
    let avgPace: Double?
    let paceMinPerKm: Double?
    let totalKm: Double?
    let distanceKm: Double?
    let sessionCount: Int?
    let durationMin: Double?
    let avgBpm: Double?

    var id: String {
        [weekStart, monthStart, sessionDate, sessionId.map(String.init)].compactMap { $0 }.joined(separator: "-")
    }

    var primaryLabel: String {
        weekStart ?? monthStart ?? sessionDate ?? "측정값"
    }

    var detailPairs: [(String, String)] {
        var pairs: [(String, String)] = []
        if let value = avgPace ?? paceMinPerKm {
            pairs.append(("페이스", Formatters.pace(value)))
        }
        if let value = totalKm ?? distanceKm {
            pairs.append(("거리", Formatters.distance(value)))
        }
        if let value = sessionCount {
            pairs.append(("세션", "\(value)회"))
        }
        if let value = durationMin {
            pairs.append(("시간", "\(Int(value))분"))
        }
        if let value = avgBpm {
            pairs.append(("심박", "\(Int(value))bpm"))
        }
        return pairs
    }
}

struct HealthQueryResponse: Codable {
    let data: [StructuredMetricRow]
    let query: QueryDescriptor
    let context: QueryContext
    let error: String?
}

struct InterpretedPeriod: Codable {
    let type: String
    let value: Int?
}

struct NextAction: Codable, Identifiable {
    let tool: String
    let arguments: [String: JSONValue]
    let reason: String

    var id: String { "\(tool)-\(reason)" }
}

struct MatchedConcept: Codable, Identifiable {
    let key: String
    let label: String
    let dbView: String?
    let dbColumn: String?
    let sqlHint: String?
    let calculation: String?
    let interpretation: JSONValue?
    let edgeCases: [String]?
    let commonMisuse: String?
    let guidelines: [String]?

    var id: String { key }
}

struct HealthInterpretResponse: Codable {
    let matchedConcepts: [MatchedConcept]
    let isTrendQuery: Bool
    let intent: String
    let period: InterpretedPeriod
    let aggregation: String
    let nextActions: [NextAction]
    let userBaseline: UserProfile
}

struct InsightAnalysis: Codable {
    let metric: String
    let latestValue: Double?
    let previousValue: Double?
    let targetValue: Double?
    let gapToTarget: Double?
    let trend: String?
    let insight: String
    let guidelines: [String]?
    let weekOverWeekChange: Double?
    let loadRatio: Double?
    let avgRestDays: Double?
    let avgSessionBpm: Double?
    let restingHeartRate: Double?
    let hrGapFromRest: Double?
    let status: String?
}

struct RecoverySignals: Codable {
    let avgRestDays: Double?
    let avgBpm: Double?
    let restingHeartRate: Double?
    let latestKm: Double?
    let previousKm: Double?
    let loadRatio: Double?
}

struct InsightUserContext: Codable {
    let runningGoal: String?
    let targetPaceMinKm: Double?
    let weeklyTargetKm: Double?
}

struct HealthInsightResponse: Codable {
    let metric: String
    let weeks: Int
    let series: [WeeklySeriesPoint]
    let analysis: InsightAnalysis
    let signals: RecoverySignals?
    let userContext: InsightUserContext
    let error: String?
}

struct RecommendationInput: Codable {
    let location: String
    let lat: Double
    let lon: Double
}

struct WeatherSummary: Codable {
    let tempC: Double?
    let isCold: Bool
    let raw: JSONValue
}

struct RunningCourse: Codable, Identifiable {
    let id: Int?
    let name: String?
    let location: String?
    let distanceKm: Double?
    let coldSuitable: Int?
    let description: String?
}

struct RecommendationUserContext: Codable {
    let runningGoal: String?
    let targetPaceMinKm: Double?
    let preferredDistanceKm: [Double]?
}

struct RunningRecommendResponse: Codable {
    let input: RecommendationInput
    let weather: WeatherSummary
    let recentPaceMinKm: Double?
    let suggestedPaceMinKm: Double?
    let courses: [RunningCourse]
    let coldTips: [String]
    let userContext: RecommendationUserContext
    let error: String?
}

struct NaturalLanguageToolResult: Codable {
    let tool: String
    let arguments: [String: JSONValue]
    let reason: String?
    let result: JSONValue
}

struct NaturalLanguageResponse: Codable {
    let userQuery: String
    let interpretation: HealthInterpretResponse
    let toolResults: [NaturalLanguageToolResult]
    let reply: String
}

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty(String)
    case failed(String)

    var isLoading: Bool {
        self == .loading
    }
}
