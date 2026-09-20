import SwiftUI

struct HairBarView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var settings: AppSettings
    let openSettings: () -> Void

    @State private var hovered = false

    var body: some View {
        VStack(spacing: 0) {
            compactBar
                .padding(.horizontal, 10)
                .frame(height: 22)

            if hovered {
                expandedContent
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 328, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: hovered ? 16 : 9, style: .continuous)
                .fill(.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: hovered ? 16 : 9, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 0.5)
                )
        )
        .contentShape(Rectangle())
        .onHover { inside in
            withAnimation(.snappy(duration: 0.22)) {
                hovered = inside
            }
        }
        .contextMenu {
            Button("Refresh now") {
                Task { await store.refresh() }
            }
            Button("Settings…", action: openSettings)
            Divider()
            Button("Quit Codex Hair Bar") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    @ViewBuilder
    private var compactBar: some View {
        switch store.state {
        case .loading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.mini)
                Text("Codex")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("Loading…")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

        case .failed:
            HStack(spacing: 7) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text("Codex")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("Unavailable")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

        case .live(let snapshot):
            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                ForEach(snapshot.headlineWindows) { window in
                    CompactMeter(window: window, showRemaining: settings.showRemaining)
                }

                Spacer(minLength: 2)

                if store.isRefreshing {
                    ProgressView().controlSize(.mini)
                }
            }
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        Divider().overlay(.white.opacity(0.08))

        switch store.state {
        case .loading:
            Text("Reading your local Codex session…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Refresh") { Task { await store.refresh() } }
                    Button("Settings…", action: openSettings)
                }
                .controlSize(.small)
            }
            .padding(.top, 8)

        case .live(let snapshot):
            VStack(spacing: 8) {
                HStack {
                    Text(snapshot.plan ?? "Codex")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    if let credit = snapshot.creditBalance {
                        Text("Credit \(credit)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(snapshot.windows) { window in
                    WindowRow(window: window, showRemaining: settings.showRemaining)
                }

                HStack {
                    Text("Updated \(snapshot.observedAt, style: .relative) ago")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh now")
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct CompactMeter: View {
    let window: UsageWindow
    let showRemaining: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(shortLabel)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.10))
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * window.clampedUsage)
                }
            }
            .frame(width: 48, height: 4)

            Text(valueText)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(width: 29, alignment: .trailing)
        }
    }

    private var shortLabel: String {
        if window.windowSeconds <= 6 * 3_600 { return "5h" }
        if window.windowSeconds <= 8 * 86_400 { return "7d" }
        return "lim"
    }

    private var valueText: String {
        let value = showRemaining ? window.remainingFraction : window.clampedUsage
        return "\(Int((value * 100).rounded()))%"
    }

    private var tint: Color {
        switch window.clampedUsage {
        case ..<0.70: return .green
        case ..<0.85: return .yellow
        case ..<0.95: return .orange
        default: return .red
        }
    }
}

private struct WindowRow: View {
    let window: UsageWindow
    let showRemaining: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(window.label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Text(valueText)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            ProgressView(value: window.clampedUsage)
                .progressViewStyle(.linear)
                .tint(tint)

            HStack {
                Spacer()
                Text(window.resetDescription)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var valueText: String {
        let value = showRemaining ? window.remainingFraction : window.clampedUsage
        return "\(Int((value * 100).rounded()))% \(showRemaining ? "left" : "used")"
    }

    private var tint: Color {
        switch window.clampedUsage {
        case ..<0.70: return .green
        case ..<0.85: return .yellow
        case ..<0.95: return .orange
        default: return .red
        }
    }
}
