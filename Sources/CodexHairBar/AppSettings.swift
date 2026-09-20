import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let refreshInterval = "refreshInterval"
        static let barVisible = "barVisible"
        static let showRemaining = "showRemaining"
        static let launchAtLogin = "launchAtLogin"
    }

    @Published var refreshInterval: TimeInterval {
        didSet {
            refreshInterval = Self.allowedRefreshIntervals.contains(refreshInterval) ? refreshInterval : 120
            UserDefaults.standard.set(refreshInterval, forKey: Key.refreshInterval)
        }
    }

    @Published var barVisible: Bool {
        didSet { UserDefaults.standard.set(barVisible, forKey: Key.barVisible) }
    }

    @Published var showRemaining: Bool {
        didSet { UserDefaults.standard.set(showRemaining, forKey: Key.showRemaining) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin)
            guard Bundle.main.bundleURL.pathExtension == "app" else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = (SMAppService.mainApp.status == .enabled)
            }
        }
    }

    static let allowedRefreshIntervals: [TimeInterval] = [60, 120, 300, 600]

    init(defaults: UserDefaults = .standard) {
        let savedInterval = defaults.double(forKey: Key.refreshInterval)
        refreshInterval = Self.allowedRefreshIntervals.contains(savedInterval) ? savedInterval : 120
        barVisible = defaults.object(forKey: Key.barVisible) as? Bool ?? true
        showRemaining = defaults.object(forKey: Key.showRemaining) as? Bool ?? true
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool
            ?? (SMAppService.mainApp.status == .enabled)
    }
}
