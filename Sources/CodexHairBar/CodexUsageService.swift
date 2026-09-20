import Foundation

struct CodexUsageService: Sendable {
    var authFile = URL(fileURLWithPath: NSHomeDirectory())
        .appending(path: ".codex/auth.json")
    var endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    func fetch() async throws -> CodexUsageSnapshot {
        let credentials = try loadCredentials()

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 20
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        if let accountID = credentials.accountID, !accountID.isEmpty {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CodexUsageError.invalidResponse
            }

            switch http.statusCode {
            case 200:
                return try Self.parseUsageResponse(data)
            case 401, 403:
                throw CodexUsageError.unauthorized
            case 429:
                throw CodexUsageError.rateLimited
            default:
                throw CodexUsageError.server(http.statusCode)
            }
        } catch let error as CodexUsageError {
            throw error
        } catch {
            throw CodexUsageError.transport(error.localizedDescription)
        }
    }

    private struct Credentials: Sendable {
        let accessToken: String
        let accountID: String?
    }

    private func loadCredentials() throws -> Credentials {
        guard
            let data = try? Data(contentsOf: authFile),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tokens = root["tokens"] as? [String: Any],
            let accessToken = tokens["access_token"] as? String,
            !accessToken.isEmpty
        else {
            throw CodexUsageError.missingCredentials
        }

        return Credentials(
            accessToken: accessToken,
            accountID: tokens["account_id"] as? String
        )
    }

    static func parseUsageResponse(_ data: Data, now: Date = Date()) throws -> CodexUsageSnapshot {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CodexUsageError.invalidResponse
        }

        var windows: [UsageWindow] = []

        if let rateLimit = root["rate_limit"] as? [String: Any] {
            windows.append(contentsOf: parseWindows(
                rateLimit,
                idPrefix: "account",
                scope: nil
            ))
        }

        for extra in root["additional_rate_limits"] as? [[String: Any]] ?? [] {
            guard let rateLimit = extra["rate_limit"] as? [String: Any] else { continue }
            let scope = extra["limit_name"] as? String
            let id = (extra["metered_feature"] as? String) ?? scope ?? "model"
            windows.append(contentsOf: parseWindows(
                rateLimit,
                idPrefix: id,
                scope: scope
            ))
        }

        guard !windows.isEmpty else {
            throw CodexUsageError.invalidResponse
        }

        let credits = root["credits"] as? [String: Any]
        let balance: String?
        if credits?["unlimited"] as? Bool == true {
            balance = nil
        } else {
            balance = credits?["balance"] as? String
        }

        return CodexUsageSnapshot(
            plan: (root["plan_type"] as? String).map(planDisplayName),
            windows: windows,
            creditBalance: balance,
            observedAt: now
        )
    }

    private static func parseWindows(
        _ limit: [String: Any],
        idPrefix: String,
        scope: String?
    ) -> [UsageWindow] {
        ["primary_window", "secondary_window"].compactMap { key in
            guard
                let node = limit[key] as? [String: Any],
                let usedPercent = number(node["used_percent"])
            else {
                return nil
            }

            let seconds = number(node["limit_window_seconds"]).map(Int.init) ?? 0
            let reset = number(node["reset_at"]).map { Date(timeIntervalSince1970: $0) }
            let base = scope?.trimmingCharacters(in: .whitespacesAndNewlines)
            let duration = durationLabel(seconds)
            let label = (base?.isEmpty == false) ? "\(base!) · \(duration)" : duration

            return UsageWindow(
                id: "\(idPrefix).\(key)",
                label: label,
                usedFraction: usedPercent / 100,
                windowSeconds: seconds,
                resetsAt: reset
            )
        }
    }

    private static func number(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func durationLabel(_ seconds: Int) -> String {
        switch seconds {
        case 1...(6 * 3_600):
            return "5 hour"
        case 1...(8 * 86_400):
            return "Weekly"
        case 1...(32 * 86_400):
            return "Monthly"
        default:
            guard seconds > 0 else { return "Usage" }
            let hours = max(1, seconds / 3_600)
            return "\(hours) hour"
        }
    }

    private static func planDisplayName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "plus": return "ChatGPT Plus"
        case "pro": return "ChatGPT Pro"
        case "prolite": return "ChatGPT Pro 5×"
        case "team", "business": return "ChatGPT Business"
        case "enterprise": return "ChatGPT Enterprise"
        default:
            return raw
        }
    }
}
