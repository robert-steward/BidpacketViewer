import Foundation

@Observable
final class BidpacketViewModel {
    var bidpacket: Bidpacket?
    var selectedRotation: Rotation?
    var errorMessage: String?

    private var currentSelectionKey: String?

    var selectedRotationIDs: Set<String> = [] {
        didSet {
            saveSelectedRotationsForCurrentBidpacket()
        }
    }

    var primaryBase: String {
        rotations.first?.base ?? "—"
    }

    var rotationCount: Int {
        rotations.count
    }

    var instanceCount: Int {
        rotations.reduce(0) { total, rotation in
            total + (rotation.occurrences ?? 1)
        }
    }

    var selectedCount: Int {
        selectedRotationIDs.count
    }

    var rotations: [Rotation] {
        bidpacket?.results ?? []
    }

    var selectedRotations: [Rotation] {
        rotations.filter { selectedRotationIDs.contains($0.id) }
    }

    func isSelected(_ rotation: Rotation) -> Bool {
        selectedRotationIDs.contains(rotation.id)
    }

    func toggleSelected(_ rotation: Rotation) {
        if selectedRotationIDs.contains(rotation.id) {
            selectedRotationIDs.remove(rotation.id)
        } else {
            selectedRotationIDs.insert(rotation.id)
        }
    }

    func clearSelectedRotations() {
        selectedRotationIDs.removeAll()
    }

    func loadSample() {
        do {
            let loaded = try BidpacketLoader.loadSampleBidpacket()
            bidpacket = loaded
            selectedRotation = loaded.results.first

            currentSelectionKey = makeSelectionKey(for: loaded)
            loadSelectedRotationsForCurrentBidpacket()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makeSelectionKey(for bidpacket: Bidpacket) -> String {
        let base = bidpacket.results.first?.base ?? "UNKNOWN_BASE"
        let aircraft = bidpacket.aircraft ?? "UNKNOWN_AIRCRAFT"
        let year = bidpacket.bidpacketYear ?? 0
        let month = bidpacket.bidpacketMonth ?? 0

        return "selected_rotations_\(base)_\(aircraft)_\(year)_\(month)"
    }

    private func saveSelectedRotationsForCurrentBidpacket() {
        guard let currentSelectionKey else {
            return
        }

        let ids = Array(selectedRotationIDs)
        UserDefaults.standard.set(ids, forKey: currentSelectionKey)
    }

    private func loadSelectedRotationsForCurrentBidpacket() {
        guard let currentSelectionKey else {
            selectedRotationIDs = []
            return
        }

        let ids = UserDefaults.standard.stringArray(forKey: currentSelectionKey) ?? []
        selectedRotationIDs = Set(ids)
    }

    var baseSummaries: [BaseSummary] {
        guard let summaryByBase = bidpacket?.summaryByBase else {
            return []
        }

        return summaryByBase
            .map { key, value in
                BaseSummary(
                    base: value.base.isEmpty ? key : value.base,
                    averageScore: value.averageScore,
                    rotationCount: value.rotationCount
                )
            }
            .sorted { $0.base < $1.base }
    }
}
