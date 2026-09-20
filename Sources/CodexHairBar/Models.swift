import Foundation

struct UsageWindow: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let usedFraction: Double
    let windowSeconds: Int
    let resetsAt: Date?

    var clampedUsage: Double { min(max(usedFraction, 0), 1) }

    var remainingFraction: Double { 1 - clampedUsage }

    var resetDescription: String {
        guard let resetsAt else { return "No reset time" }
        let remaining = max(0, resetsAt.timeIntervalSinceNow)
        if remaining < 60 { return "Resets in <1m" }
        if remaining < 3_600 { return "Resets in \(Int(remaining / 60))m" }
        if remaining < 86_400 {
            let hours = Int(remaining / 3_600)
            let minutes = Int(remaining.truncatingRemainder(dividingBy: 3_600) / 60)
            return minutes == 0 ? "Resets in \(hours)h" : "Resets in \(hours)h \(minutes)m"
        }
        let days = Int(remaining / 86_400)
        let hours = Int(remaining.truncatingRemainder(dividingBy: 86_400) / 3_600)
        return hours == 0 ? "Resets in \(days)d" : "Resets in \(days)d \(hours)h"
    }
}

struct CodexUsageSnapshot: Equatable, Sendable {
    let plan: String?
    let windows: [UsageWindow]
    let creditBalance: String?
    let observedAt: Date

    var headlineWindows: [UsageWindow] {
        Array(windows.sorted { lhs, rhs in
            if lhs.windowSeconds != rhs.windowSeconds { return lhs.windowSeconds < rhs.windowSeconds }
            return lhs.label < rhs.label
        }.prefix(2))
    }
}

enum UsageViewState: Equatable, Sendable {
    case loading
    case live(CodexUsageSnapshot)
    case failed(String)
}

enum CodexUsageError: LocalizedError {
    case missingCredentials
    case unauthorized
    case rateLimited
    case invalidResponse
    case server(Int)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Codex is not signed in. Run codex login first."
        case .unauthorized:
            return "The local Codex login has expired. Open Codex or run codex login again."
        case .rateLimited:
            return "Codex temporarily rate-limited the usage request."
        case .invalidResponse:
            return "Codex returned an unreadable usage response."
        case .server(let code):
            return "Codex usage endpoint returned HTTP \(code)."
        case .transport(let message):
            return message
        }
    }
}
