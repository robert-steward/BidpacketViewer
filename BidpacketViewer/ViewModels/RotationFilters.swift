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

enum RedeyeFilterMode: String, CaseIterable, Identifiable {
    case all
    case noRedeye
    case anyRedeye
    case firstDP
    case middleDP
    case lastDP

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All rotations"
        case .noRedeye: return "No redeye"
        case .anyRedeye: return "Any redeye"
        case .firstDP: return "First DP"
        case .middleDP: return "Middle DP"
        case .lastDP: return "Last DP"
        }
    }
}

enum CircadianSwapFilterMode: String, CaseIterable, Identifiable {
    case all
    case any
    case pmToAm
    case redeyeToAm
    case amToPm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All rotations"
        case .any: return "Any"
        case .pmToAm: return "PM to AM"
        case .redeyeToAm: return "Redeye to AM"
        case .amToPm: return "AM to PM"
        }
    }
}

enum CircadianMitigationFilterMode: String, CaseIterable, Identifiable {
    case all
    case mitigated
    case unmitigated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .mitigated: return "Mitigated"
        case .unmitigated: return "Unmitigated"
        }
    }
}

enum WeekendTouchFilterMode: String, CaseIterable, Identifiable {
    case all
    case touchesWeekend
    case avoidsWeekend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All rotations"
        case .touchesWeekend: return "Touches weekend"
        case .avoidsWeekend: return "Avoids weekend"
        }
    }
}

enum ComparisonFilterMode: String, CaseIterable, Identifiable {
    case all
    case greaterThanOrEqual
    case lessThanOrEqual
    case equalTo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All rotations"
        case .greaterThanOrEqual: return "≥"
        case .lessThanOrEqual: return "≤"
        case .equalTo: return "="
        }
    }
}

enum BooleanChoiceFilterMode: String, CaseIterable, Identifiable {
    case any
    case yes
    case no

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any: return "Any"
        case .yes: return "Yes"
        case .no: return "No"
        }
    }
}

struct RotationFilters {
    // MARK: - Basic

    var selectedDayLengths: Set<Int> = []
    var selectedStartDays: Set<String> = []
    var startDateString: String = ""

    var weekendTouchMode: WeekendTouchFilterMode = .all

    var selectedBase: String = ""
    var selectedPosition: String = ""

    // MARK: - Operational

    var redEyeOnly = false
    var dayLayoverOnly = false
    var crossTownOnly = false
    var startsDeadheadOnly = false
    var endsDeadheadOnly = false

    var fullyCommutableOnly = false
    var commuteInOnly = false
    var commuteHomeOnly = false

    var frontDeadheadMode: BooleanChoiceFilterMode = .any
    var backDeadheadMode: BooleanChoiceFilterMode = .any
    var redeyeMode: BooleanChoiceFilterMode = .any

    var circadianSwapMode: CircadianSwapFilterMode = .all
    var circadianMitigationMode: CircadianMitigationFilterMode = .all
    
    // MARK: - Dates

    var touchDateStrings: Set<String> = []
    var touchDateMode: TouchDateFilterMode = .include

    // MARK: - Text / Station Filters

    var checkInStationText: String = ""
    var overnightStationText: String = ""
    var touchesStationText: String = ""

    // MARK: - Numeric Filters

    var frequencyMode: ComparisonFilterMode = .all
    var frequencyValue: Int?

    var dutyPeriodsMode: ComparisonFilterMode = .all
    var dutyPeriodsValue: Int?

    var maxLegsMode: ComparisonFilterMode = .all
    var maxLegsValue: Int?

    var daysWithLegsDaysValue: Int?
    var daysWithLegsLegsValue: Int?

    // MARK: - Time Filters, Stored as Minutes

    var totalCreditMode: ComparisonFilterMode = .all
    var totalCreditMinutes: Int?

    var nonBlockCreditMode: ComparisonFilterMode = .all
    var nonBlockCreditMinutes: Int?

    var creditPerDayMode: ComparisonFilterMode = .all
    var creditPerDayMinutes: Int?

    var tafbMode: ComparisonFilterMode = .all
    var tafbMinutes: Int?

    var longestSitMinutes: Int?

    var longestFDPMode: ComparisonFilterMode = .all
    var longestFDPMinutes: Int?

    var layoverLengthMinMinutes: Int?
    var layoverLengthMaxMinutes: Int?

    var checkInMode: ComparisonFilterMode = .all
    var checkInMinutes: Int?

    var releaseMode: ComparisonFilterMode = .all
    var releaseMinutes: Int?

    // MARK: - Efficiency

    var dutyEfficiencyMode: ComparisonFilterMode = .all
    var dutyEfficiencyValue: Double?

    // MARK: - Recovery Filters

    var fdpRecoveryRestMinutes: Int?
    var fdpRecoveryFDPMinutes: Int?

    var legsRecoveryRestMinutes: Int?
    var legsRecoveryLegsBefore: Int?

    var blockRecoveryRestMinutes: Int?
    var blockRecoveryBlockMinutes: Int?
    
    var redeyeFilterMode: RedeyeFilterMode = .all
    
    var sitPayMinimum: Double?
    var edpPayMinimum: Double?
    var holPayMinimum: Double?
    var carvePayMinimum: Double?

    // MARK: - State

    var hasActiveFilters: Bool {
        !selectedDayLengths.isEmpty ||
        !selectedStartDays.isEmpty ||
        redeyeFilterMode != .all ||
        !startDateString.isEmpty ||
        weekendTouchMode != .all ||
        !selectedBase.isEmpty ||
        !selectedPosition.isEmpty ||
        circadianSwapMode != .all ||
        circadianMitigationMode != .all ||

        sitPayMinimum != nil ||
        edpPayMinimum != nil ||
        holPayMinimum != nil ||
        carvePayMinimum != nil ||
        redEyeOnly ||
        dayLayoverOnly ||
        crossTownOnly ||
        startsDeadheadOnly ||
        endsDeadheadOnly ||
        fullyCommutableOnly ||
        commuteInOnly ||
        commuteHomeOnly ||
        frontDeadheadMode != .any ||
        backDeadheadMode != .any ||
        redeyeMode != .any ||

        !touchDateStrings.isEmpty ||

        !checkInStationText.isEmpty ||
        !overnightStationText.isEmpty ||
        !touchesStationText.isEmpty ||

        frequencyMode != .all ||
        dutyPeriodsMode != .all ||
        maxLegsMode != .all ||
        daysWithLegsDaysValue != nil ||
        daysWithLegsLegsValue != nil ||

        totalCreditMode != .all ||
        nonBlockCreditMode != .all ||
        creditPerDayMode != .all ||
        tafbMode != .all ||
        longestSitMinutes != nil ||
        longestFDPMinutes != nil ||
        layoverLengthMinMinutes != nil ||
        layoverLengthMaxMinutes != nil ||
        checkInMode != .all ||
        releaseMode != .all ||

        dutyEfficiencyMode != .all ||

        fdpRecoveryRestMinutes != nil ||
        fdpRecoveryFDPMinutes != nil ||
        legsRecoveryRestMinutes != nil ||
        legsRecoveryLegsBefore != nil ||
        blockRecoveryRestMinutes != nil ||
        blockRecoveryBlockMinutes != nil
    }

    mutating func clearAll() {
        selectedDayLengths.removeAll()
        selectedStartDays.removeAll()
        startDateString = ""

        weekendTouchMode = .all
        redeyeFilterMode = .all
        circadianSwapMode = .all
        circadianMitigationMode = .all
        
        sitPayMinimum = nil
        edpPayMinimum = nil
        holPayMinimum = nil
        carvePayMinimum = nil

        selectedBase = ""
        selectedPosition = ""

        redEyeOnly = false
        dayLayoverOnly = false
        crossTownOnly = false
        startsDeadheadOnly = false
        endsDeadheadOnly = false

        fullyCommutableOnly = false
        commuteInOnly = false
        commuteHomeOnly = false

        frontDeadheadMode = .any
        backDeadheadMode = .any
        redeyeMode = .any

        touchDateStrings.removeAll()
        touchDateMode = .include

        checkInStationText = ""
        overnightStationText = ""
        touchesStationText = ""

        frequencyMode = .all
        frequencyValue = nil

        dutyPeriodsMode = .all
        dutyPeriodsValue = nil

        maxLegsMode = .all
        maxLegsValue = nil

        daysWithLegsDaysValue = nil
        daysWithLegsLegsValue = nil

        totalCreditMode = .all
        totalCreditMinutes = nil

        nonBlockCreditMode = .all
        nonBlockCreditMinutes = nil

        creditPerDayMode = .all
        creditPerDayMinutes = nil

        tafbMode = .all
        tafbMinutes = nil

        longestSitMinutes = nil
        longestFDPMode = .all
        longestFDPMinutes = nil

        layoverLengthMinMinutes = nil
        layoverLengthMaxMinutes = nil

        checkInMode = .all
        checkInMinutes = nil

        releaseMode = .all
        releaseMinutes = nil

        dutyEfficiencyMode = .all
        dutyEfficiencyValue = nil

        fdpRecoveryRestMinutes = nil
        fdpRecoveryFDPMinutes = nil

        legsRecoveryRestMinutes = nil
        legsRecoveryLegsBefore = nil

        blockRecoveryRestMinutes = nil
        blockRecoveryBlockMinutes = nil
    }
}
