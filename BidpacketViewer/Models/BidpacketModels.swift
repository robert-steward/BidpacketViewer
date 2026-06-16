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
    let totalCredit: TimeValue?
    let finalScore: Double?
    let rawChunkText: String?
    let occurrences: Int?
    let effectiveDates: [String]?
    let overnights: String?

    enum CodingKeys: String, CodingKey {
        case rotationNumber = "rotation_num"
        case base
        case position
        case numDays = "num_days"
        case totalCredit = "total_credit"
        case finalScore = "final_score"
        case rawChunkText = "chunk"
        case occurrences
        case effectiveDates = "effective_dates"
        case overnights
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        rotationNumber = try container.decode(String.self, forKey: .rotationNumber)
        base = try container.decodeIfPresent(String.self, forKey: .base)
        position = try container.decodeIfPresent(String.self, forKey: .position)
        numDays = try container.decodeIfPresent(Int.self, forKey: .numDays)
        totalCredit = try container.decodeIfPresent(TimeValue.self, forKey: .totalCredit)
        finalScore = try container.decodeIfPresent(Double.self, forKey: .finalScore)
        rawChunkText = try container.decodeIfPresent(String.self, forKey: .rawChunkText)
        occurrences = try container.decodeIfPresent(Int.self, forKey: .occurrences)
        effectiveDates = try container.decodeIfPresent([String].self, forKey: .effectiveDates)

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
