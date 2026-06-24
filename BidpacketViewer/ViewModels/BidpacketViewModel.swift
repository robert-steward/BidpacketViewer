import Foundation

@Observable
final class BidpacketViewModel {
    var bidpacket: Bidpacket?
    var selectedRotation: Rotation?
    var errorMessage: String?
    var filters = RotationFilters()
    var bidpacketName: String?

    var aircraft: String {
        guard let bidpacketName else { return "—" }
        return String(bidpacketName.split(separator: "_").first ?? "—")
    }

    private var currentSelectionKey: String?

    var selectedRotationIDs: Set<String> = [] {
        didSet {
            saveSelectedRotationsForCurrentBidpacket()
        }
    }

    
    var rotations: [Rotation] {
        bidpacket?.results ?? []
    }
    
    var summary: PacketSummary? {
        bidpacket?.summaryByBase
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
        summary?.countUnique ?? rotations.count
    }

    var instanceCount: Int {
        summary?.count ?? rotations.reduce(0) { $0 + occurrenceWeight($1) }
    }

    var totalRedeyes: Int {
        summary?.redeyesTotal ?? rotations.reduce(0) {
            $0 + (($1.numRedeyes ?? 0) * occurrenceWeight($1))
        }
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


    var totalDayLayovers: Int {
        summary?.dayLayoversTotal ?? rotations.reduce(0) {
            $0 + (($1.dayLayovers ?? 0) * occurrenceWeight($1))
        }
    }

    var totalCrossTownLayovers: Int {
        summary?.xtownLayoversTotal ?? rotations.reduce(0) {
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
        summary?.commutability?.fullyCommutable ?? rotations.reduce(0) {
            $0 + (($1.fullyCommutable == true) ? occurrenceWeight($1) : 0)
        }
    }
    
    
    var frontOnlyCommutableCount: Int {
        summary?.commutability?.frontOnly ?? rotations.reduce(0) { total, rotation in
            let isFrontOnly =
                rotation.frontCommutable == true &&
                rotation.backCommutable != true &&
                rotation.fullyCommutable != true

            return total + (isFrontOnly ? occurrenceWeight(rotation) : 0)
        }
    }

    var backOnlyCommutableCount: Int {
        summary?.commutability?.backOnly ?? rotations.reduce(0) { total, rotation in
            let isBackOnly =
                rotation.backCommutable == true &&
                rotation.frontCommutable != true &&
                rotation.fullyCommutable != true

            return total + (isBackOnly ? occurrenceWeight(rotation) : 0)
        }
    }
    
    var notCommutableCount: Int {
        summary?.commutability?.notCommutable ?? rotations.reduce(0) { total, rotation in
            let isCommutable =
                rotation.frontCommutable == true ||
                rotation.backCommutable == true ||
                rotation.fullyCommutable == true

            return total + (!isCommutable ? occurrenceWeight(rotation) : 0)
        }
    }
    
    var circadianSwapTotal: Int {
        summary?.circadianSwaps?.total ?? rotations.reduce(0) {
            let swaps = $1.circadianSwaps
            let total = (swaps?.amToPm ?? 0) + (swaps?.pmToAm ?? 0) + (swaps?.redeyeToAm ?? 0)
            return $0 + (total * occurrenceWeight($1))
        }
    }

    var mitigatedCircadianSwapTotal: Int {
        summary?.mitigatedCircadianSwaps?.total ?? rotations.reduce(0) {
            let swaps = $1.mitigatedCircadianSwaps
            let total = (swaps?.amToPm ?? 0) + (swaps?.pmToAm ?? 0) + (swaps?.redeyeToAm ?? 0)
            return $0 + (total * occurrenceWeight($1))
        }
    }
    
    var circadianPmToAmCount: Int {
        summary?.circadianSwaps?.pmToAm ?? 0
    }

    var circadianRedeyeToAmCount: Int {
        summary?.circadianSwaps?.redeyeToAm ?? 0
    }

    var circadianAmToPmCount: Int {
        summary?.circadianSwaps?.amToPm ?? 0
    }

    var mitigatedPmToAmCount: Int {
        summary?.mitigatedCircadianSwaps?.pmToAm ?? 0
    }

    var mitigatedRedeyeToAmCount: Int {
        summary?.mitigatedCircadianSwaps?.redeyeToAm ?? 0
    }

    var mitigatedAmToPmCount: Int {
        summary?.mitigatedCircadianSwaps?.amToPm ?? 0
    }
    
    var avgRestNoRedeyeHM: String {
        summary?.avgRestNoRedeye?.hm ?? "—"
    }

    var avgRestWithRedeyeHM: String {
        summary?.avgRestWithRedeye?.hm ?? "—"
    }

    var avgRestNoRedeyeOvernightsCount: Int {
        summary?.avgRestNoRedeye?.overnightsCount ?? 0
    }

    var avgRestWithRedeyeOvernightsCount: Int {
        summary?.avgRestWithRedeye?.overnightsCount ?? 0
    }
    
    var frontNoEarlierThan: String {
        summary?.commuteWindow?.frontNoEarlierThan ?? "—"
    }

    var backNoLaterThan: String {
        summary?.commuteWindow?.backNoLaterThan ?? "—"
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

    var creditByLength: [(label: String, rotations: Int, instances: Int, blockMinutes: Int, creditMinutes: Int, avgCreditPerInstance: Int)] {
        let buckets: [(String, (Int?) -> Bool)] = [
            ("1 Day", { $0 == 1 }),
            ("2 Day", { $0 == 2 }),
            ("3 Day", { $0 == 3 }),
            ("4 Day", { $0 == 4 }),
            ("5+ Day", { ($0 ?? 0) >= 5 })
        ]

        return buckets.map { label, matcher in
            let matching = rotations.filter { matcher($0.numDays) }

            let instances = matching.reduce(0) {
                $0 + occurrenceWeight($1)
            }

            let creditMinutes = matching.reduce(0) {
                $0 + (($1.totalCredit?.minutes ?? 0) * occurrenceWeight($1))
            }

            // Approximate block using total credit minus non-block credit.
            // If nonBlockCredit is missing, it falls back to total credit.
            let blockMinutes = matching.reduce(0) { total, rotation in
                let weight = occurrenceWeight(rotation)
                let credit = rotation.totalCredit?.minutes ?? 0
                let nonBlock = rotation.nonBlockCredit?.minutes ?? 0
                return total + max(credit - nonBlock, 0) * weight
            }

            let avgCredit = instances > 0 ? creditMinutes / instances : 0

            return (
                label: label,
                rotations: matching.count,
                instances: instances,
                blockMinutes: blockMinutes,
                creditMinutes: creditMinutes,
                avgCreditPerInstance: avgCredit
            )
        }
    }
    
    var coTerminalDepartures: [(station: String, count: Int)] {
        guard primaryBase == "NYC" || primaryBase == "LAX" else {
            return []
        }

        var counts: [String: Int] = [:]

        for rotation in rotations {
            guard rotation.base?.uppercased() == primaryBase else {
                continue
            }

            guard let station = rotation.checkInStation?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased(),
                  !station.isEmpty else {
                continue
            }

            counts[station, default: 0] += occurrenceWeight(rotation)
        }

        return counts
            .map { (station: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    
    var coTerminalTotal: Int {
        coTerminalDepartures.reduce(0) { $0 + $1.count }
    }

    var packetBase: String {
        if let base = summary?.base {
            return base.uppercased()
        }

        if let firstBase = rotations.first?.base {
            return firstBase.uppercased()
        }

        return "—"
    }

    var rotationMixTargets: RotationMixTargets? {
        bidpacket?.summaryBase?.rotationMix
    }

    var rotationMixWeight: Double {
        bidpacket?.summaryBase?.weights?[packetBase]?.rotationMixWeight ?? 0
    }
    

    var rotationMixRows: [(label: String, actual: Double, target: Double)] {
        let total = Double(max(instanceCount, 1))
        let targets = rotationMixTargets

        func actualPercent(_ matcher: (Rotation) -> Bool) -> Double {
            let count = rotations
                .filter(matcher)
                .reduce(0) { $0 + occurrenceWeight($1) }

            return Double(count) / total * 100.0
        }

        return [
            ("1", actualPercent { $0.numDays == 1 }, targets?.oneDay ?? 0),
            ("2", actualPercent { $0.numDays == 2 }, targets?.twoDay ?? 0),
            ("3", actualPercent { $0.numDays == 3 }, targets?.threeDay ?? 0),
            ("4", actualPercent { $0.numDays == 4 }, targets?.fourDay ?? 0),
            ("5", actualPercent { $0.numDays == 5 }, targets?.fiveDay ?? 0),
            ("6+", actualPercent { ($0.numDays ?? 0) >= 6 }, targets?.sixPlusDay ?? 0)
        ]
    }

    var rotationMixScore: Double {
        let deadband = 2.0
        let maxDiff = 10.0

        func contribution(actual: Double, target: Double) -> Double {
            let diff = abs(actual - target)

            if diff <= deadband {
                return 1.0
            }

            if diff >= maxDiff {
                return 0.0
            }

            return 1.0 - ((diff - deadband) / (maxDiff - deadband))
        }

        let rows = rotationMixRows
        guard !rows.isEmpty else { return 0 }

        let sum = rows.reduce(0.0) {
            $0 + contribution(actual: $1.actual, target: $1.target)
        }

        let score = (sum / Double(rows.count)) * 10.0
        return (score * 1000).rounded() / 1000
    }
    var averageDutyPeriods: Double {
        let totalInstances = instanceCount
        guard totalInstances > 0 else { return 0 }

        let total = rotations.reduce(0) {
            $0 + (($1.numDutyPeriods ?? 0) * occurrenceWeight($1))
        }

        return Double(total) / Double(totalInstances)
    }

    var averageLegsPerDay: Double {
        let totalInstances = instanceCount
        guard totalInstances > 0 else { return 0 }

        let total = rotations.reduce(0.0) {
            $0 + (($1.avgLegsPerDay ?? 0) * Double(occurrenceWeight($1)))
        }

        return total / Double(totalInstances)
    }

    var averageDutyEfficiency: Double {
        let totalInstances = instanceCount
        guard totalInstances > 0 else { return 0 }

        let total = rotations.reduce(0.0) {
            $0 + (($1.dutyEfficiency ?? 0) * Double(occurrenceWeight($1)))
        }

        return total / Double(totalInstances)
    }

    var averageTAFB: Double {
        let totalInstances = instanceCount
        guard totalInstances > 0 else { return 0 }

        let total = rotations.reduce(0.0) {
            $0 + (($1.tafb ?? 0) * Double(occurrenceWeight($1)))
        }

        return total / Double(totalInstances)
    }

    var lastDutyOneLegRows: [(label: String, count: Int, percent: Double)] {
        let buckets: [(String, (Int?) -> Bool)] = [
            ("Overall", { _ in true }),
            ("1 Day", { $0 == 1 }),
            ("2 Day", { $0 == 2 }),
            ("3 Day", { $0 == 3 }),
            ("4 Day", { $0 == 4 }),
            ("5+ Day", { ($0 ?? 0) >= 5 })
        ]

        return buckets.map { label, matcher in
            let matching = rotations.filter { matcher($0.numDays) }

            let totalInstances = matching.reduce(0) {
                $0 + occurrenceWeight($1)
            }

            let oneLegInstances = matching.reduce(0) { total, rotation in
                guard rotation.legs?.last == 1 else { return total }
                return total + occurrenceWeight(rotation)
            }

            let percent = totalInstances > 0
                ? Double(oneLegInstances) / Double(totalInstances)
                : 0

            return (
                label: label,
                count: oneLegInstances,
                percent: percent
            )
        }
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
        if let activeFileName = LocalBidpacketStore.activeBidpacketFileName(),
           !activeFileName.isEmpty {
            do {
                let data = try LocalBidpacketStore.load(fileName: activeFileName)
                loadFromData(data)
                return
            } catch {
                errorMessage = "Could not load active bidpacket \(activeFileName). Loaded sample instead.\n\(error.localizedDescription)"
            }
        }

        do {
            let loaded = try BidpacketLoader.loadSampleBidpacket()

            bidpacketName = loaded.name
            bidpacket = loaded.bidpacket
            selectedRotation = loaded.bidpacket.results.first

            currentSelectionKey = makeSelectionKey(for: loaded.bidpacket)
            loadSelectedRotationsForCurrentBidpacket()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadFromData(_ data: Data) {
        do {
            let loaded = try BidpacketLoader.loadBidpacket(from: data)

            bidpacketName = loaded.name
            bidpacket = loaded.bidpacket
            selectedRotation = loaded.bidpacket.results.first

            currentSelectionKey = makeSelectionKey(for: loaded.bidpacket)
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

    func occurrenceWeight(_ rotation: Rotation) -> Int {
        max(rotation.occurrences ?? 1, 1)
    }

    private func makeSelectionKey(for bidpacket: Bidpacket) -> String {
        let base = bidpacket.summaryByBase?.base
            ?? bidpacket.results.first?.base
            ?? "UNKNOWN_BASE"

        let packetName = bidpacketName ?? "UNKNOWN_PACKET"

        return "selected_rotations_\(base)_\(packetName)"
    }

    private func minutesFromTAFBDouble(_ value: Double) -> Int {
        let hours = Int(value)
        let rawMinutes = (value - Double(hours)) * 100
        let minutes = Int(rawMinutes.rounded())

        return hours * 60 + minutes
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

    private func dateFromISODateString(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        return formatter.date(from: value)
    }

    private func shortWeekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        return formatter.string(from: date)
    }

    private func isWeekend(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date)

        return weekday == 1 || weekday == 7
    }

    private func rotationStartWeekdays(_ rotation: Rotation) -> Set<String> {
        Set(
            (rotation.effectiveDates ?? []).compactMap { dateString in
                guard let date = dateFromISODateString(dateString) else {
                    return nil
                }

                return shortWeekdayString(from: date)
            }
        )
    }

    private func rotationTouchesWeekend(_ rotation: Rotation) -> Bool {
        (rotation.effectiveDates ?? []).contains { dateString in
            guard let date = dateFromISODateString(dateString) else {
                return false
            }

            return isWeekend(date)
        }
    }
    
    private func matchesCircadianSwapFilter(_ rotation: Rotation) -> Bool {
        guard filters.circadianSwapMode != .all ||
              filters.circadianMitigationMode != .all else {
            return true
        }

        let raw = rotation.circadianSwaps
        let mitigated = rotation.mitigatedCircadianSwaps

        func rawCount(for mode: CircadianSwapFilterMode) -> Int {
            switch mode {
            case .all:
                return totalCircadianCount(raw)
            case .any:
                return totalCircadianCount(raw)
            case .pmToAm:
                return raw?.pmToAm ?? 0
            case .redeyeToAm:
                return raw?.redeyeToAm ?? 0
            case .amToPm:
                return raw?.amToPm ?? 0
            }
        }

        func mitigatedCount(for mode: CircadianSwapFilterMode) -> Int {
            switch mode {
            case .all:
                return totalCircadianCount(mitigated)
            case .any:
                return totalCircadianCount(mitigated)
            case .pmToAm:
                return mitigated?.pmToAm ?? 0
            case .redeyeToAm:
                return mitigated?.redeyeToAm ?? 0
            case .amToPm:
                return mitigated?.amToPm ?? 0
            }
        }

        let swapMode = filters.circadianSwapMode == .all ? .any : filters.circadianSwapMode

        let rawMatches = rawCount(for: swapMode) > 0
        let mitigatedMatches = mitigatedCount(for: swapMode) > 0
        let unmitigatedMatches = rawCount(for: swapMode) > mitigatedCount(for: swapMode)

        switch filters.circadianMitigationMode {
        case .all:
            return rawMatches

        case .mitigated:
            return mitigatedMatches

        case .unmitigated:
            return unmitigatedMatches
        }
    }

    private func totalCircadianCount(_ swaps: CircadianSwaps?) -> Int {
        (swaps?.pmToAm ?? 0) +
        (swaps?.redeyeToAm ?? 0) +
        (swaps?.amToPm ?? 0)
    }
    
    private func matchesFilters(_ rotation: Rotation) -> Bool {
        
        if !matchesRedeyeFilter(rotation) {
            return false
        }

        if !filters.selectedDayLengths.isEmpty {
            let days = rotation.numDays ?? 0

            let matchesLength: Bool

            if days >= 5 {
                matchesLength = filters.selectedDayLengths.contains(5)
            } else {
                matchesLength = filters.selectedDayLengths.contains(days)
            }

            if !matchesLength {
                return false
            }
        }

        if filters.redEyeOnly {
            if (rotation.numRedeyes ?? 0) <= 0 {
                return false
            }
        }

        if filters.dayLayoverOnly {
            if (rotation.dayLayovers ?? 0) <= 0 {
                return false
            }
        }

        if filters.crossTownOnly {
            if (rotation.xtownLayover ?? 0) <= 0 {
                return false
            }
        }

        if filters.startsDeadheadOnly {
            if rotation.frontDH != true {
                return false
            }
        }

        if filters.endsDeadheadOnly {
            if rotation.backDH != true {
                return false
            }
        }

        if filters.fullyCommutableOnly {
            if rotation.fullyCommutable != true {
                return false
            }
        }

        if filters.commuteInOnly {
            if rotation.frontCommutable != true {
                return false
            }
        }

        if filters.commuteHomeOnly {
            if rotation.backCommutable != true {
                return false
            }
        }

        if !filters.touchDateStrings.isEmpty {
            let effectiveDates = Set(rotation.effectiveDates ?? [])

            let touchesAnySelectedDate =
                !filters.touchDateStrings.isDisjoint(with: effectiveDates)

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
        
        

        if !passesComparison(
            value: rotation.numDutyPeriods,
            mode: filters.dutyPeriodsMode,
            target: filters.dutyPeriodsValue
        ) {
            return false
        }
        if !passesComparison(
            value: minutesFromClockString(rotation.checkIn),
            mode: filters.checkInMode,
            target: filters.checkInMinutes
        ) {
            return false
        }

        if !passesComparison(
            value: minutesFromClockString(rotation.checkOut),
            mode: filters.releaseMode,
            target: filters.releaseMinutes
        ) {
            return false
        }

        if !passesComparison(
            value: rotation.totalCredit?.minutes,
            mode: filters.totalCreditMode,
            target: filters.totalCreditMinutes
        ) {
            return false
        }

        if !passesComparison(
            value: rotation.creditPerDay?.minutes,
            mode: filters.creditPerDayMode,
            target: filters.creditPerDayMinutes
        ) {
            return false
        }

        if !passesComparison(
            value: rotation.nonBlockCredit?.minutes,
            mode: filters.nonBlockCreditMode,
            target: filters.nonBlockCreditMinutes
        ) {
            return false
        }

        if !passesComparison(
            value: rotation.tafb.map { minutesFromTAFBDouble($0) },
            mode: filters.tafbMode,
            target: filters.tafbMinutes
        ) {
            return false
        }
        
        if !passesComparison(
            value: rotation.maxLegs,
            mode: filters.maxLegsMode,
            target: filters.maxLegsValue
        ) {
            return false
        }
        
        if !filters.selectedBase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let wanted = filters.selectedBase.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if rotation.base?.uppercased() != wanted {
                return false
            }
        }

        if !filters.selectedPosition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let wanted = filters.selectedPosition.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if rotation.position?.uppercased() != wanted {
                return false
            }
        }

        if !filters.checkInStationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let wanted = filters.checkInStationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if rotation.checkInStation?.uppercased() != wanted {
                return false
            }
        }

        if !filters.overnightStationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let wanted = filters.overnightStationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if rotation.overnights?.uppercased().contains(wanted) != true {
                return false
            }
        }

        if !filters.touchesStationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let wanted = filters.touchesStationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            if rotation.rawChunkText?.uppercased().contains(wanted) != true {
                return false
            }
        }
        
        if !passesComparison(
            value: rotation.occurrences,
            mode: filters.frequencyMode,
            target: filters.frequencyValue
        ) {
            return false
        }

        if !passesComparison(
            value: rotation.dutyEfficiency,
            mode: filters.dutyEfficiencyMode,
            target: filters.dutyEfficiencyValue
        ) {
            return false
        }

        if !passesComparison(
            value: rotation.longestFDP?.minutes,
            mode: filters.longestFDPMode,
            target: filters.longestFDPMinutes
        ) {
            return false
        }
        
        if !filters.selectedStartDays.isEmpty {
            let startWeekdays = rotationStartWeekdays(rotation)

            if filters.selectedStartDays.isDisjoint(with: startWeekdays) {
                return false
            }
        }

        switch filters.weekendTouchMode {
        case .all:
            break

        case .touchesWeekend:
            if !rotationTouchesWeekend(rotation) {
                return false
            }

        case .avoidsWeekend:
            if rotationTouchesWeekend(rotation) {
                return false
            }
        }
        
        if let longestSitMinutes = filters.longestSitMinutes {
            let rotationLongestSit = longestDurationMinutes(from: rotation.sits)

            guard let rotationLongestSit,
                  rotationLongestSit >= longestSitMinutes else {
                return false
            }
        }

        if !hasLayoverWithinRange(
            rotation,
            minMinutes: filters.layoverLengthMinMinutes,
            maxMinutes: filters.layoverLengthMaxMinutes
        ) {
            return false
        }
        
        if !matchesDaysWithLegsFilter(rotation) {
            return false
        }
        
        if !matchesCircadianSwapFilter(rotation) {
            return false
        }
        
        if !matchesExtraPayFilter(rotation) {
            return false
        }
        
        return true
    }
    
    private func matchesExtraPayFilter(_ rotation: Rotation) -> Bool {

        if let minimum = filters.sitPayMinimum {
            if (rotation.pay?.sit ?? 0) < minimum {
                return false
            }
        }

        if let minimum = filters.edpPayMinimum {
            if (rotation.pay?.edp ?? 0) < minimum {
                return false
            }
        }

        if let minimum = filters.holPayMinimum {
            if (rotation.pay?.hol ?? 0) < minimum {
                return false
            }
        }

        if let minimum = filters.carvePayMinimum {
            if (rotation.pay?.carve ?? 0) < minimum {
                return false
            }
        }

        return true
    }
    
    private func matchesDaysWithLegsFilter(
        _ rotation: Rotation
    ) -> Bool {
        let requiredDayCount = filters.daysWithLegsDaysValue
        let minimumLegs = filters.daysWithLegsLegsValue

        guard requiredDayCount != nil || minimumLegs != nil else {
            return true
        }

        guard let requiredDayCount,
              let minimumLegs,
              let legs = rotation.legs else {
            return false
        }

        let matchingDayCount = legs.filter { $0 >= minimumLegs }.count

        return matchingDayCount >= requiredDayCount
    }
    
    
    private func passesComparison<T: Comparable>(
        value: T?,
        mode: ComparisonFilterMode,
        target: T?
    ) -> Bool {
        guard mode != .all else {
            return true
        }

        guard let value, let target else {
            return false
        }

        switch mode {
        case .all:
            return true
        case .greaterThanOrEqual:
            return value >= target
        case .lessThanOrEqual:
            return value <= target
        case .equalTo:
            return value == target
        }
    }
    
    private func minutesFromClockString(_ value: String?) -> Int? {
        guard let value else {
            return nil
        }

        let digits = value.filter { $0.isNumber }

        guard digits.count == 3 || digits.count == 4 else {
            return nil
        }

        let padded = digits.count == 3 ? "0\(digits)" : digits

        guard let hours = Int(padded.prefix(2)),
              let minutes = Int(padded.suffix(2)),
              hours >= 0,
              hours <= 23,
              minutes >= 0,
              minutes <= 59 else {
            return nil
        }

        return hours * 60 + minutes
    }
    
    private static let filterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private func minutesFromDurationString(_ value: String) -> Int? {
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")

        if cleaned.contains(":") {
            let parts = cleaned.split(separator: ":").compactMap { Int($0) }

            guard parts.count == 2 else {
                return nil
            }

            return parts[0] * 60 + parts[1]
        }

        let parts = cleaned.split(separator: ".").compactMap { Int($0) }

        guard parts.count == 2 else {
            return nil
        }

        return parts[0] * 60 + parts[1]
    }

    private func longestDurationMinutes(from values: [String]?) -> Int? {
        values?
            .compactMap { minutesFromDurationString($0) }
            .max()
    }

    private func hasLayoverWithinRange(
        _ rotation: Rotation,
        minMinutes: Int?,
        maxMinutes: Int?
    ) -> Bool {
        guard minMinutes != nil || maxMinutes != nil else {
            return true
        }

        let layoverMinutes = (rotation.layoverTimes ?? [])
            .compactMap { minutesFromDurationString($0) }

        guard !layoverMinutes.isEmpty else {
            return false
        }

        return layoverMinutes.contains { minutes in
            if let minMinutes, minutes < minMinutes {
                return false
            }

            if let maxMinutes, minutes > maxMinutes {
                return false
            }
            
            if !matchesFDPRecoveryFilter(rotation) {
                return false
            }

            if !matchesLegsRecoveryFilter(rotation) {
                return false
            }

            if !matchesBlockRecoveryFilter(rotation) {
                return false
            }

            return true
        }
    }
    
    private func matchesFDPRecoveryFilter(_ rotation: Rotation) -> Bool {
        guard filters.fdpRecoveryRestMinutes != nil ||
              filters.fdpRecoveryFDPMinutes != nil else {
            return true
        }

        guard let maxRestMinutes = filters.fdpRecoveryRestMinutes,
              let minimumFDPMinutes = filters.fdpRecoveryFDPMinutes,
              let restWindows = rotation.restWindows else {
            return false
        }

        return restWindows.contains { window in
            (window.restMinutes ?? Int.max) <= maxRestMinutes &&
            (window.fdpBeforeMinutes ?? 0) >= minimumFDPMinutes
        }
    }

    private func matchesRedeyeFilter(_ rotation: Rotation) -> Bool {
        switch filters.redeyeFilterMode {
        case .all:
            return true

        case .noRedeye:
            return (rotation.numRedeyes ?? 0) == 0

        case .anyRedeye:
            return (rotation.numRedeyes ?? 0) > 0

        case .firstDP:
            return (rotation.redeyePosition?.first ?? 0) > 0

        case .middleDP:
            return (rotation.redeyePosition?.middle ?? 0) > 0

        case .lastDP:
            return (rotation.redeyePosition?.last ?? 0) > 0
        }
    }
    
    
    private func matchesLegsRecoveryFilter(_ rotation: Rotation) -> Bool {
        guard filters.legsRecoveryRestMinutes != nil ||
              filters.legsRecoveryLegsBefore != nil else {
            return true
        }

        guard let maxRestMinutes = filters.legsRecoveryRestMinutes,
              let minimumLegsBefore = filters.legsRecoveryLegsBefore,
              let restWindows = rotation.restWindows else {
            return false
        }

        return restWindows.contains { window in
            (window.restMinutes ?? Int.max) <= maxRestMinutes &&
            (window.legsBefore ?? 0) >= minimumLegsBefore
        }
    }

    private func matchesBlockRecoveryFilter(_ rotation: Rotation) -> Bool {
        guard filters.blockRecoveryRestMinutes != nil ||
              filters.blockRecoveryBlockMinutes != nil else {
            return true
        }

        guard let maxRestMinutes = filters.blockRecoveryRestMinutes,
              let minimumBlockMinutes = filters.blockRecoveryBlockMinutes,
              let restWindows = rotation.restWindows else {
            return false
        }

        return restWindows.contains { window in
            (window.restMinutes ?? Int.max) <= maxRestMinutes &&
            (window.blockBeforeMinutes ?? 0) >= minimumBlockMinutes
        }
    }
 
    
    
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
    
    }
