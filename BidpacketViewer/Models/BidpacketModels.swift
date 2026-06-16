import Foundation

struct BidpacketFile: Decodable {
    let id: String?
    let name: String?
    let savedAt: String?
    let payload: Bidpacket

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case savedAt = "saved_at"
        case payload
    }
}

struct Bidpacket: Decodable {
    let aircraft: String?
    let bidpacketYear: Int?
    let bidpacketMonth: Int?
    let bidpacketDate: String?
    let summary: BidpacketSummary?
    let summaryByBase: [String: BaseSummary]?
    let results: [Rotation]

    enum CodingKeys: String, CodingKey {
        case aircraft
        case bidpacketYear = "bidpacket_year"
        case bidpacketMonth = "bidpacket_month"
        case bidpacketDate = "bidpacket_date"
        case summary
        case summaryByBase = "summary_by_base"
        case results
    }
}

struct BidpacketSummary: Decodable {
    let averageScore: Double?
    let rotationCount: Int?

    enum CodingKeys: String, CodingKey {
        case averageScore = "avg_all"
        case rotationCount = "count"
    }
}

struct BaseSummary: Decodable, Identifiable {
    var id: String { base }

    let base: String
    let averageScore: Double?
    let rotationCount: Int?

    enum CodingKeys: String, CodingKey {
        case base
        case averageScore = "avg_all"
        case rotationCount = "count"
    }
}

struct Rotation: Decodable, Identifiable {
    var id: String {
        "\(rotationNumber)-\(base ?? "")-\(position ?? "")"
    }

    let rotationNumber: String
    let base: String?
    let position: String?

    let numDays: Int?
    let numDutyPeriods: Int?
    let occurrences: Int?
    let effectiveDates: [String]?

    let checkIn: String?
    let checkInStation: String?
    let checkOut: String?

    let totalCredit: TimeValue?
    let creditPerDay: TimeValue?
    let nonBlockCredit: TimeValue?
    let longestFDP: TimeValue?

    let finalScore: Double?
    let rawChunkText: String?

    let overnights: String?
    let layoverTimes: [String]?
    let overnightsNoRedeye: Int?
    let overnightsWRedeye: Int?

    let numRedeyes: Int?
    let redeyePosition: RedeyePosition?

    let dayLayovers: Int?
    let dayLayoversDHOnly: Int?
    let xtownLayover: Int?

    let frontCommutable: Bool?
    let backCommutable: Bool?
    let fullyCommutable: Bool?

    let frontDH: Bool?
    let backDH: Bool?

    let avgLegsPerDay: Double?
    let maxLegs: Int?
    let legs: [Int]?

    let restNoRedeyeMinutes: Int?
    let restWRedeyeMinutes: Int?
    let restWindows: [RestWindow]?

    let circadianSwaps: CircadianSwaps?
    let mitigatedCircadianSwaps: CircadianSwaps?

    let dutyEfficiency: Double?
    let tafb: Double?

    let pay: PayValues?
    let scoreParts: ScoreParts?
    let touches: [String: Int]?
    let sits: [String]?

    enum CodingKeys: String, CodingKey {
        case rotationNumber = "rotation_num"
        case base
        case position

        case numDays = "num_days"
        case numDutyPeriods = "num_duty_periods"
        case occurrences
        case effectiveDates = "effective_dates"

        case checkIn = "check_in"
        case checkInStation = "check_in_station"
        case checkOut = "check_out"

        case totalCredit = "total_credit"
        case creditPerDay = "credit_per_day"
        case nonBlockCredit = "non_block_credit"
        case longestFDP = "longest_fdp"

        case finalScore = "final_score"
        case rawChunkText = "chunk"

        case overnights
        case layoverTimes = "layover_times"
        case overnightsNoRedeye = "overnights_no_redeye"
        case overnightsWRedeye = "overnights_wredeye"

        case numRedeyes = "num_redeyes"
        case redeyePosition = "redeye_position"

        case dayLayovers = "day_layovers"
        case dayLayoversDHOnly = "day_layovers_dh_only"
        case xtownLayover = "xtown_layover"

        case frontCommutable = "front_commutable"
        case backCommutable = "back_commutable"
        case fullyCommutable = "fully_commutable"

        case frontDH = "front_dh"
        case backDH = "back_dh"

        case avgLegsPerDay = "avg_legs_per_day"
        case maxLegs = "max_legs"
        case legs

        case restNoRedeyeMinutes = "rest_no_redeye_minutes"
        case restWRedeyeMinutes = "rest_wredeye_minutes"
        case restWindows = "rest_windows"

        case circadianSwaps = "circadian_swaps"
        case mitigatedCircadianSwaps = "mitigated_circadian_swaps"

        case dutyEfficiency = "duty_efficiency"
        case tafb

        case pay
        case scoreParts = "score_parts"
        case touches
        case sits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        rotationNumber = try container.decode(String.self, forKey: .rotationNumber)
        base = try container.decodeIfPresent(String.self, forKey: .base)
        position = try container.decodeIfPresent(String.self, forKey: .position)

        numDays = try container.decodeIfPresent(Int.self, forKey: .numDays)
        numDutyPeriods = try container.decodeIfPresent(Int.self, forKey: .numDutyPeriods)
        occurrences = try container.decodeIfPresent(Int.self, forKey: .occurrences)
        effectiveDates = try container.decodeIfPresent([String].self, forKey: .effectiveDates)

        checkIn = try container.decodeIfPresent(String.self, forKey: .checkIn)
        checkInStation = try container.decodeIfPresent(String.self, forKey: .checkInStation)
        checkOut = try container.decodeIfPresent(String.self, forKey: .checkOut)

        totalCredit = try container.decodeIfPresent(TimeValue.self, forKey: .totalCredit)
        creditPerDay = try container.decodeIfPresent(TimeValue.self, forKey: .creditPerDay)
        nonBlockCredit = try container.decodeIfPresent(TimeValue.self, forKey: .nonBlockCredit)
        longestFDP = try container.decodeIfPresent(TimeValue.self, forKey: .longestFDP)

        finalScore = try container.decodeIfPresent(Double.self, forKey: .finalScore)
        rawChunkText = try container.decodeIfPresent(String.self, forKey: .rawChunkText)

        layoverTimes = try container.decodeIfPresent([String].self, forKey: .layoverTimes)
        overnightsNoRedeye = try container.decodeIfPresent(Int.self, forKey: .overnightsNoRedeye)
        overnightsWRedeye = try container.decodeIfPresent(Int.self, forKey: .overnightsWRedeye)

        numRedeyes = try container.decodeIfPresent(Int.self, forKey: .numRedeyes)
        redeyePosition = try container.decodeIfPresent(RedeyePosition.self, forKey: .redeyePosition)

        dayLayovers = try container.decodeIfPresent(Int.self, forKey: .dayLayovers)
        dayLayoversDHOnly = try container.decodeIfPresent(Int.self, forKey: .dayLayoversDHOnly)
        xtownLayover = try container.decodeIfPresent(Int.self, forKey: .xtownLayover)

        frontCommutable = try container.decodeIfPresent(Bool.self, forKey: .frontCommutable)
        backCommutable = try container.decodeIfPresent(Bool.self, forKey: .backCommutable)
        fullyCommutable = try container.decodeIfPresent(Bool.self, forKey: .fullyCommutable)

        frontDH = try container.decodeIfPresent(Bool.self, forKey: .frontDH)
        backDH = try container.decodeIfPresent(Bool.self, forKey: .backDH)

        avgLegsPerDay = try container.decodeIfPresent(Double.self, forKey: .avgLegsPerDay)
        maxLegs = try container.decodeIfPresent(Int.self, forKey: .maxLegs)
        legs = try container.decodeIfPresent([Int].self, forKey: .legs)

        restNoRedeyeMinutes = try container.decodeIfPresent(Int.self, forKey: .restNoRedeyeMinutes)
        restWRedeyeMinutes = try container.decodeIfPresent(Int.self, forKey: .restWRedeyeMinutes)
        restWindows = try container.decodeIfPresent([RestWindow].self, forKey: .restWindows)

        circadianSwaps = try container.decodeIfPresent(CircadianSwaps.self, forKey: .circadianSwaps)
        mitigatedCircadianSwaps = try container.decodeIfPresent(CircadianSwaps.self, forKey: .mitigatedCircadianSwaps)

        dutyEfficiency = try container.decodeIfPresent(Double.self, forKey: .dutyEfficiency)
        tafb = try container.decodeIfPresent(Double.self, forKey: .tafb)

        pay = try container.decodeIfPresent(PayValues.self, forKey: .pay)
        scoreParts = try container.decodeIfPresent(ScoreParts.self, forKey: .scoreParts)
        touches = try container.decodeIfPresent([String: Int].self, forKey: .touches)
        sits = try container.decodeIfPresent([String].self, forKey: .sits)

        if let overnightString = try? container.decode(String.self, forKey: .overnights) {
            overnights = overnightString
        } else {
            overnights = nil
        }
    }
}

struct TimeValue: Decodable {
    let hm: String?
    let minutes: Int?
}

struct RedeyePosition: Decodable {
    let first: Int?
    let middle: Int?
    let last: Int?
}

struct CircadianSwaps: Decodable {
    let amToPm: Int?
    let pmToAm: Int?
    let redeyeToAm: Int?

    enum CodingKeys: String, CodingKey {
        case amToPm = "am_to_pm"
        case pmToAm = "pm_to_am"
        case redeyeToAm = "redeye_to_am"
    }
}

struct RestWindow: Decodable {
    let fromDay: String?
    let toDay: String?

    let restHM: String?
    let restMinutes: Int?

    let blockBeforeHM: String?
    let blockBeforeMinutes: Int?
    let blockAfterHM: String?
    let blockAfterMinutes: Int?

    let fdpBeforeHM: String?
    let fdpBeforeMinutes: Int?
    let fdpAfterHM: String?
    let fdpAfterMinutes: Int?

    let legsBefore: Int?
    let legsAfter: Int?

    enum CodingKeys: String, CodingKey {
        case fromDay = "from_day"
        case toDay = "to_day"

        case restHM = "rest_hm"
        case restMinutes = "rest_min"

        case blockBeforeHM = "block_before_hm"
        case blockBeforeMinutes = "block_before_min"
        case blockAfterHM = "block_after_hm"
        case blockAfterMinutes = "block_after_min"

        case fdpBeforeHM = "fdp_before_hm"
        case fdpBeforeMinutes = "fdp_before_min"
        case fdpAfterHM = "fdp_after_hm"
        case fdpAfterMinutes = "fdp_after_min"

        case legsBefore = "legs_before"
        case legsAfter = "legs_after"
    }
}

struct PayValues: Decodable {
    let tl: Double?
    let sit: Double?
    let edp: Double?
    let hol: Double?
    let carve: Double?

    enum CodingKeys: String, CodingKey {
        case tl = "TL"
        case sit = "SIT"
        case edp = "EDP"
        case hol = "HOL"
        case carve = "CARVE"
    }
}

struct ScoreParts: Decodable {
    let fdpOverMaxFDP: Double?
    let woclScore: Double?
    let blockOverFDP: Double?
    let blockOverMaxFDP: Double?
    let blockOverMaxBlock: Double?
    let cirSwapScore: Double?
    let commutabilityScore: Double?
    let dhScore: Double?
    let inScore: Double?
    let legsScore: Double?
    let outScore: Double?
    let payTafbScore: Double?
    let restScore: Double?
    let turnScore: Double?

    enum CodingKeys: String, CodingKey {
        case fdpOverMaxFDP = "FDP_over_MaxFDP"
        case woclScore = "WOCL_score"
        case blockOverFDP = "block_over_FDP"
        case blockOverMaxFDP = "block_over_MAXFDP"
        case blockOverMaxBlock = "block_over_maxBlock"
        case cirSwapScore = "cir_swap_score"
        case commutabilityScore = "commutability_score"
        case dhScore = "dh_score"
        case inScore = "in_score"
        case legsScore = "legs_score"
        case outScore = "out_score"
        case payTafbScore = "pay_tafb_score"
        case restScore = "rest_score"
        case turnScore = "turn_score"
    }
}
