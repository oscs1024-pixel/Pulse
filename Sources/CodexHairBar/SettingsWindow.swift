import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings, store: UsageStore) {
        let view = SettingsView(settings: settings, store: store)
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "Codex Hair Bar Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 430, height: 320))
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var store: UsageStore

    var body: some View {
        Form {
            Section("Hair Bar") {
                Toggle("Show floating bar", isOn: $settings.barVisible)
                Toggle("Show remaining percentage", isOn: $settings.showRemaining)
            }

            Section("Refresh") {
                Picker("Refresh every", selection: $settings.refreshInterval) {
                    Text("1 minute").tag(TimeInterval(60))
                    Text("2 minutes").tag(TimeInterval(120))
                    Text("5 minutes").tag(TimeInterval(300))
                    Text("10 minutes").tag(TimeInterval(600))
                }

                Button("Refresh now") {
                    Task { await store.refresh() }
                }
                .disabled(store.isRefreshing)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Privacy") {
                Text("Codex Hair Bar reads ~/.codex/auth.json locally and sends the existing Codex access token only to chatgpt.com to request your account's usage windows. Credentials are never copied into app preferences.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding(16)
        .frame(minWidth: 430, minHeight: 320)
    }
}
