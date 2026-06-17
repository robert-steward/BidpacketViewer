import Foundation

@Observable
final class BidpacketViewModel {
    var bidpacket: Bidpacket?
    var selectedRotation: Rotation?
    var errorMessage: String?
    var filters = RotationFilters()

    private var currentSelectionKey: String?

    var selectedRotationIDs: Set<String> = [] {
        didSet {
            saveSelectedRotationsForCurrentBidpacket()
        }
    }

    var rotations: [Rotation] {
        bidpacket?.results ?? []
    }

    var filteredRotations: [Rotation] {
        rotations.filter { rotation in
            matchesFilters(rotation)
        }
    }
    
    var selectedRotations: [Rotation] {
        rotations.filter { selectedRotationIDs.contains($0.id) }
    }

    var primaryBase: String {
        rotations.first?.base ?? "—"
    }

    var rotationCount: Int {
        rotations.count
    }

    var instanceCount: Int {
        rotations.reduce(0) { $0 + occurrenceWeight($1) }
    }

    var selectedCount: Int {
        selectedRotationIDs.count
    }

    var selectedInstanceCount: Int {
        selectedRotations.reduce(0) { $0 + occurrenceWeight($1) }
    }

    var totalCreditMinutes: Int {
        rotations.reduce(0) {
            $0 + (($1.totalCredit?.minutes ?? 0) * occurrenceWeight($1))
        }
    }

    var selectedCreditMinutes: Int {
        selectedRotations.reduce(0) {
            $0 + (($1.totalCredit?.minutes ?? 0) * occurrenceWeight($1))
        }
    }

    var averageCreditPerInstanceMinutes: Int {
        guard instanceCount > 0 else { return 0 }
        return totalCreditMinutes / instanceCount
    }

    var selectedAverageCreditPerInstanceMinutes: Int {
        guard selectedInstanceCount > 0 else { return 0 }
        return selectedCreditMinutes / selectedInstanceCount
    }

    var rotationsByLength: [(label: String, rotations: Int, instances: Int)] {
        let buckets: [(String, (Int?) -> Bool)] = [
            ("1 Day", { $0 == 1 }),
            ("2 Day", { $0 == 2 }),
            ("3 Day", { $0 == 3 }),
            ("4 Day", { $0 == 4 }),
            ("5+ Day", { ($0 ?? 0) >= 5 })
        ]

        return buckets.map { label, matcher in
            let matching = rotations.filter { matcher($0.numDays) }
            let instances = matching.reduce(0) { $0 + occurrenceWeight($1) }

            return (
                label: label,
                rotations: matching.count,
                instances: instances
            )
        }
    }

    var totalRedeyes: Int {
        rotations.reduce(0) {
            $0 + (($1.numRedeyes ?? 0) * occurrenceWeight($1))
        }
    }

    var totalDayLayovers: Int {
        rotations.reduce(0) {
            $0 + (($1.dayLayovers ?? 0) * occurrenceWeight($1))
        }
    }

    var totalCrossTownLayovers: Int {
        rotations.reduce(0) {
            $0 + (($1.xtownLayover ?? 0) * occurrenceWeight($1))
        }
    }

    var frontDeadheadCount: Int {
        rotations.reduce(0) {
            $0 + (($1.frontDH == true) ? occurrenceWeight($1) : 0)
        }
    }

    var backDeadheadCount: Int {
        rotations.reduce(0) {
            $0 + (($1.backDH == true) ? occurrenceWeight($1) : 0)
        }
    }

    var fullyCommutableCount: Int {
        rotations.reduce(0) {
            $0 + (($1.fullyCommutable == true) ? occurrenceWeight($1) : 0)
        }
    }

    var frontOnlyCommutableCount: Int {
        rotations.reduce(0) { total, rotation in
            let isFrontOnly =
                rotation.frontCommutable == true &&
                rotation.backCommutable != true &&
                rotation.fullyCommutable != true

            return total + (isFrontOnly ? occurrenceWeight(rotation) : 0)
        }
    }

    var backOnlyCommutableCount: Int {
        rotations.reduce(0) { total, rotation in
            let isBackOnly =
                rotation.backCommutable == true &&
                rotation.frontCommutable != true &&
                rotation.fullyCommutable != true

            return total + (isBackOnly ? occurrenceWeight(rotation) : 0)
        }
    }

    var topOvernights: [(station: String, count: Int)] {
        var counts: [String: Int] = [:]

        for rotation in rotations {
            let weight = occurrenceWeight(rotation)

            guard let overnights = rotation.overnights else {
                continue
            }

            for part in overnights.split(separator: ",") {
                let station = part
                    .split(separator: ":")
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let station, !station.isEmpty {
                    counts[station, default: 0] += weight
                }
            }
        }

        return counts
            .map { (station: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }

    var maxLegsInAnyDutyPeriod: Int {
        rotations.compactMap { $0.maxLegs }.max() ?? 0
    }

    var longestFDPMinutes: Int {
        rotations.compactMap { $0.longestFDP?.minutes }.max() ?? 0
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
    
    func loadFromData(_ data: Data) {
        do {
            let loaded = try BidpacketLoader.loadBidpacket(from: data)

            bidpacket = loaded
            selectedRotation = loaded.results.first

            currentSelectionKey = makeSelectionKey(for: loaded)
            loadSelectedRotationsForCurrentBidpacket()

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func formatMinutesAsCredit(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours).\(String(format: "%02d", mins))"
    }

    func formatMinutesAsHM(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours):\(String(format: "%02d", mins))"
    }

    private func occurrenceWeight(_ rotation: Rotation) -> Int {
        max(rotation.occurrences ?? 1, 1)
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

    private func matchesFilters(_ rotation: Rotation) -> Bool {
        if !filters.selectedDayLengths.isEmpty {
            guard let numDays = rotation.numDays else {
                return false
            }

            if !filters.selectedDayLengths.contains(numDays) {
                return false
            }
        }

        if filters.redEyeOnly && (rotation.numRedeyes ?? 0) == 0 {
            return false
        }

        if filters.dayLayoverOnly && (rotation.dayLayovers ?? 0) == 0 {
            return false
        }

        if filters.crossTownOnly && (rotation.xtownLayover ?? 0) == 0 {
            return false
        }

        if filters.startsDeadheadOnly && rotation.frontDH != true {
            return false
        }

        if filters.endsDeadheadOnly && rotation.backDH != true {
            return false
        }

        if filters.fullyCommutableOnly && rotation.fullyCommutable != true {
            return false
        }

        if filters.commuteInOnly && rotation.frontCommutable != true {
            return false
        }

        if filters.commuteHomeOnly && rotation.backCommutable != true {
            return false
        }
        if !filters.touchDateStrings.isEmpty {
            let touchesAnySelectedDate = filters.touchDateStrings.contains { dateString in
                guard let date = Self.filterDateFormatter.date(from: dateString) else {
                    return false
                }

                return rotationTouchesDate(rotation, date)
            }

            switch filters.touchDateMode {
            case .include:
                if !touchesAnySelectedDate {
                    return false
                }

            case .exclude:
                if touchesAnySelectedDate {
                    return false
                }
            }
        }
        return true
    }
    
    private static let filterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private func rotationTouchesDate(_ rotation: Rotation, _ touchDate: Date) -> Bool {
        guard let effectiveDates = rotation.effectiveDates,
              let numDays = rotation.numDays else {
            return false
        }

        let calendar = Calendar.current

        let selectedDay = calendar.startOfDay(for: touchDate)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone

        for dateString in effectiveDates {
            guard let startDate = formatter.date(from: dateString) else {
                continue
            }

            let startDay = calendar.startOfDay(for: startDate)

            guard let endDay = calendar.date(
                byAdding: .day,
                value: numDays - 1,
                to: startDay
            ) else {
                continue
            }

            if selectedDay >= startDay && selectedDay <= endDay {
                return true
            }
        }

        return false
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
