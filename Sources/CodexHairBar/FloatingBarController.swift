import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingBarController {
    private let panel: NSPanel
    private let settings: AppSettings
    private var cancellables: Set<AnyCancellable> = []
    private var screenObserver: NSObjectProtocol?

    init(store: UsageStore, settings: AppSettings, openSettings: @escaping () -> Void) {
        self.settings = settings

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 328, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.panel = panel

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false

        let root = HairBarView(
            store: store,
            settings: settings,
            openSettings: openSettings
        )
        panel.contentView = NSHostingView(rootView: root)

        position()
        applyVisibility()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.position()
            }
        }

        settings.$barVisible
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.applyVisibility()
                }
            }
            .store(in: &cancellables)
    }

    func toggle() {
        settings.barVisible.toggle()
    }

    func position() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = panel.frame
        let visible = screen.visibleFrame
        let x = visible.midX - frame.width / 2
        let y = visible.maxY - 8 - frame.height
        panel.setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
    }

    private func applyVisibility() {
        if settings.barVisible {
            position()
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }
}
