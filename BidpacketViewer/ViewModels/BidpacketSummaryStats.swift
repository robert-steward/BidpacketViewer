import Foundation

struct PacketSummaryStats {
    let uniqueRotations: Int
    let totalInstances: Int

    let redEyesTotal: Int
    let crossTownLayoversTotal: Int
    let dayLayoversTotal: Int
    let dayLayoversDHOnlyTotal: Int

    let avgRestNoRedeye: AverageRestStats
    let avgRestWithRedeye: AverageRestStats

    let circadianSwaps: CircadianSwapStats
    let mitigatedCircadianSwaps: CircadianSwapStats

    let commutability: CommutabilityStats
    let commuteWindow: CommuteWindowStats?

    let avgByDays: [DayAverageStats]
    let lastDutyPeriodOneLeg: [LastDutyPeriodOneLegStats]
}

struct AverageRestStats {
    let minutes: Int
    let overnightsCount: Int
    let rotationsCount: Int

    var hhmm: String {
        "\(minutes / 60).\(String(format: "%02d", minutes % 60))"
    }
}

struct CircadianSwapStats {
    let pmToAm: Int
    let redeyeToAm: Int
    let amToPm: Int

    var total: Int {
        pmToAm + redeyeToAm + amToPm
    }
}

struct CommutabilityStats {
    let frontOnly: Int
    let backOnly: Int
    let fully: Int
    let notCommutable: Int
}

struct CommuteWindowStats {
    let netGreaterThanOrEqual: String
    let nltLessThanOrEqual: String
}

struct DayAverageStats: Identifiable {
    var id: Int { days }

    let days: Int
    let averageScore: Double
    let count: Int
    let percent: Double
}

struct LastDutyPeriodOneLegStats: Identifiable {
    var id: String { label }

    let label: String
    let value: Int
    let percent: Double
}
