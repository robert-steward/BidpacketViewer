import Foundation

enum TouchDateFilterMode: String, CaseIterable, Identifiable {
    case include
    case exclude

    var id: String { rawValue }

    var title: String {
        switch self {
        case .include: return "Include"
        case .exclude: return "Exclude"
        }
    }
}

struct RotationFilters {
    var selectedDayLengths: Set<Int> = []

    var redEyeOnly = false
    var dayLayoverOnly = false
    var crossTownOnly = false
    var startsDeadheadOnly = false
    var endsDeadheadOnly = false
    var fullyCommutableOnly = false
    var commuteInOnly = false
    var commuteHomeOnly = false

    var touchDateStrings: Set<String> = []
    var touchDateMode: TouchDateFilterMode = .include

    var hasActiveFilters: Bool {
        !selectedDayLengths.isEmpty ||
        redEyeOnly ||
        dayLayoverOnly ||
        crossTownOnly ||
        startsDeadheadOnly ||
        endsDeadheadOnly ||
        fullyCommutableOnly ||
        commuteInOnly ||
        commuteHomeOnly ||
        !touchDateStrings.isEmpty
    }

    mutating func clearAll() {
        selectedDayLengths.removeAll()
        redEyeOnly = false
        dayLayoverOnly = false
        crossTownOnly = false
        startsDeadheadOnly = false
        endsDeadheadOnly = false
        fullyCommutableOnly = false
        commuteInOnly = false
        commuteHomeOnly = false
        touchDateStrings.removeAll()
        touchDateMode = .include
    }
}
