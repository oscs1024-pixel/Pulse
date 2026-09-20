import Foundation

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var state: UsageViewState = .loading
    @Published private(set) var isRefreshing = false

    private let service: CodexUsageService
    private let settings: AppSettings
    private var refreshLoop: Task<Void, Never>?

    init(service: CodexUsageService = CodexUsageService(), settings: AppSettings) {
        self.service = service
        self.settings = settings
    }

    func start() {
        guard refreshLoop == nil else { return }
        refreshLoop = Task { [weak self] in
            guard let self else { return }
            await self.refresh()
            while !Task.isCancelled {
                let interval = self.settings.refreshInterval
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                await self.refresh()
            }
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let snapshot = try await service.fetch()
            state = .live(snapshot)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }
    }
}
