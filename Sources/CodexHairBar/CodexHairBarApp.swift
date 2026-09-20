import AppKit
import Combine
import SwiftUI

@main
struct CodexHairBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Codex Hair Bar", systemImage: "terminal.fill") {
            Button("Show / Hide Hair Bar") {
                appDelegate.toggleBar()
            }

            Button("Refresh Now") {
                appDelegate.refresh()
            }

            Divider()

            Button("Settings…") {
                appDelegate.showSettings()
            }
            .keyboardShortcut(",")

            Divider()

            Button("Quit Codex Hair Bar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()

    private lazy var store = UsageStore(settings: settings)
    private var barController: FloatingBarController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let bar = FloatingBarController(
            store: store,
            settings: settings,
            openSettings: { [weak self] in self?.showSettings() }
        )
        barController = bar

        store.start()
    }

    func toggleBar() {
        barController?.toggle()
    }

    func refresh() {
        Task { await store.refresh() }
    }

    func showSettings() {
        let controller = settingsWindow ?? SettingsWindowController(settings: settings, store: store)
        settingsWindow = controller
        controller.show()
    }
}
