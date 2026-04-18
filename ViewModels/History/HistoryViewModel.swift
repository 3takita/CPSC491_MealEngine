import Foundation

final class HistoryViewModel: ObservableObject {
    @Published var trackedDays: [TrackedDay] = []
}
