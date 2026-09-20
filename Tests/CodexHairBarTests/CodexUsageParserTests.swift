import XCTest
@testable import CodexHairBar

final class CodexUsageParserTests: XCTestCase {
    func testParsesAccountWindowsAndPlan() throws {
        let json = """
        {
          "plan_type": "plus",
          "rate_limit": {
            "primary_window": {
              "used_percent": 42,
              "limit_window_seconds": 18000,
              "reset_at": 2000000000
            },
            "secondary_window": {
              "used_percent": 73.5,
              "limit_window_seconds": 604800,
              "reset_at": 2000600000
            }
          },
          "credits": {
            "unlimited": false,
            "balance": "12.50"
          }
        }
        """

        let snapshot = try CodexUsageService.parseUsageResponse(Data(json.utf8), now: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(snapshot.plan, "ChatGPT Plus")
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.windows[0].label, "5 hour")
        XCTAssertEqual(snapshot.windows[0].usedFraction, 0.42, accuracy: 0.0001)
        XCTAssertEqual(snapshot.windows[1].label, "Weekly")
        XCTAssertEqual(snapshot.creditBalance, "12.50")
    }

    func testParsesAdditionalModelLimit() throws {
        let json = """
        {
          "rate_limit": {
            "primary_window": {
              "used_percent": 10,
              "limit_window_seconds": 604800
            }
          },
          "additional_rate_limits": [
            {
              "limit_name": "GPT-5",
              "metered_feature": "gpt5",
              "rate_limit": {
                "primary_window": {
                  "used_percent": 90,
                  "limit_window_seconds": 18000
                }
              }
            }
          ]
        }
        """

        let snapshot = try CodexUsageService.parseUsageResponse(Data(json.utf8))
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.windows[1].label, "GPT-5 · 5 hour")
    }

    func testRejectsResponseWithoutUsageWindows() {
        XCTAssertThrowsError(
            try CodexUsageService.parseUsageResponse(Data(#"{"plan_type":"plus"}"#.utf8))
        )
    }
}
