//
//  GlossaryCatalog.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 7/14/26.
//

import Foundation

struct GlossaryEntry: Identifiable {
    let id: String
    let term: String
    let definition: String
    let example: String?

    init(
        term: String,
        definition: String,
        example: String? = nil
    ) {
        self.id = term
        self.term = term
        self.definition = definition
        self.example = example
    }
}

struct GlossarySection: Identifiable {
    let id: String
    let title: String
    let entries: [GlossaryEntry]

    init(
        title: String,
        entries: [GlossaryEntry]
    ) {
        self.id = title
        self.title = title
        self.entries = entries
    }
}

enum GlossaryCatalog {
    static let sections: [GlossarySection] = [
        
            GlossarySection(
                title: "Bidpacket Basics",
                entries: [
                    GlossaryEntry(
                        term: "Rotation",
                        definition: "A unique published sequence of duty periods, flight legs, layovers, report times, release times, credit, and other operating characteristics.",
                        example: "A rotation that begins on 12 different effective dates is still one unique rotation."
                    ),
                    GlossaryEntry(
                        term: "Instance",
                        definition: "One scheduled occurrence of a rotation. The number of instances is based on the number of effective start dates listed for that rotation.",
                        example: "A rotation with 12 effective start dates counts as 1 rotation and 12 instances."
                    ),
                    GlossaryEntry(
                        term: "Frequency",
                        definition: "The number of effective start dates for a rotation during the bidpacket period. Frequency and instances represent the same underlying occurrence count when viewing an individual rotation.",
                        example: "A frequency of 8 means the rotation operates 8 times."
                    ),
                    GlossaryEntry(
                        term: "Effective Date",
                        definition: "A calendar date on which the rotation begins. Effective dates are parsed from the rotation's EFFECTIVE date range, weekday restrictions, DAILY designation, and any listed exceptions.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Selected Rotation",
                        definition: "A rotation manually marked by the user for planning, review, or export. Selecting a rotation does not change its score or filtering values.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Rotation Length",
                        definition: "The number of calendar days occupied by the rotation. It is normally based on the last duty-day letter, but may extend by one day when the final release carries sufficiently into the following calendar day.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Duty and Time",
                entries: [
                    GlossaryEntry(
                        term: "Duty Period",
                        definition: "A published duty day containing one or more flight or positioning legs. The app counts duty periods by counting the rotation day letters that contain flights.",
                        example: "A four-day rotation may have fewer than four duty periods if one calendar day contains no flying."
                    ),
                    GlossaryEntry(
                        term: "Check-in",
                        definition: "The rotation report time parsed from the published CHECK-IN AT value.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Release",
                        definition: "The calculated release time for the rotation. The parser uses the final leg's arrival time plus 30 minutes.",
                        example: "A final arrival at 18:20 produces a calculated release time of 18:50."
                    ),
                    GlossaryEntry(
                        term: "FDP",
                        definition: "Flight Duty Period. The app uses the published FDP values associated with each duty day for statistics, recovery filters, and scoring.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Longest FDP",
                        definition: "The greatest FDP value among all duty periods in the rotation.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "TAFB",
                        definition: "Time Away From Base, read from the published total-credit line. It represents the total elapsed time associated with the rotation.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Sit",
                        definition: "The elapsed time between consecutive legs when one leg arrives at the same airport from which the next leg departs.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Layover Length",
                        definition: "The published rest interval following a duty period. A rotation can have more than one layover length.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Operational Terms",
                entries: [
                    GlossaryEntry(
                        term: "Deadhead",
                        definition: "A positioning leg on which the pilot is transported rather than operating the flight. Published DH legs and ground-positioning LIMO legs are treated as deadheads.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Front Deadhead",
                        definition: "A rotation whose first leg is a deadhead.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Middle Deadhead",
                        definition: "A deadhead that occurs after the first leg and before the final leg of the rotation.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Back Deadhead",
                        definition: "A rotation whose final leg is a deadhead.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Overnight",
                        definition: "A recorded rest period following a duty day. The overnight station is identified from the final arrival airport of that duty day.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Day Layover",
                        definition: "A duty break where the calculated release and the next duty's report occur on the same acclimated calendar date, with the preceding release occurring at or after 02:00.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Deadhead-only Day Layover",
                        definition: "A day layover for which every leg in the following duty period is a deadhead.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Cross-town Layover",
                        definition: "A layover where the final arrival airport before the rest period differs from the first departure airport of the following duty period.",
                        example: "Arriving at JFK and reporting the next duty period at LGA is counted as a cross-town layover."
                    ),
                    GlossaryEntry(
                        term: "Touches Station",
                        definition: "Indicates that an airport appears in the rotation's sequence of departure or arrival stations.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Red-eyes and Circadian Swaps",
                entries: [
                    GlossaryEntry(
                        term: "Red-eye",
                        definition: "A qualifying non-westbound, non-augmented leg that intrudes into the pilot's acclimated overnight circadian window under the parser's report, flight, arrival, and release-time rules.",
                        example: "The parser evaluates the leg in the pilot's acclimated time zone rather than relying only on the airport's displayed local time."
                    ),
                    GlossaryEntry(
                        term: "Red-eye Position",
                        definition: "Identifies whether a red-eye occurs in the first, middle, or last duty period of the rotation.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Circadian Swap",
                        definition: "A qualifying change in report-time category between consecutive duty periods. The app separately identifies PM-to-AM, red-eye-to-AM, and AM-to-PM transitions.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "PM-to-AM Swap",
                        definition: "A transition from a qualifying afternoon or evening duty period to a qualifying morning duty period.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Red-eye-to-AM Swap",
                        definition: "A transition from a duty period containing a qualifying red-eye to a qualifying morning duty period.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "AM-to-PM Swap",
                        definition: "A transition from a qualifying morning duty period to a qualifying afternoon or evening duty period.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Mitigated Circadian Swap",
                        definition: "A circadian swap that meets the parser's reduced-FDP mitigation criteria. The criteria vary by swap type, report time, maximum allowable FDP, actual FDP, and in some cases the number of legs.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "WOCL",
                        definition: "Window of Circadian Low. The parser evaluates qualifying duty overlap with the acclimated 02:00–06:00 window, including a buffer before departure and after arrival.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Commutability",
                entries: [
                    GlossaryEntry(
                        term: "Commute In",
                        definition: "The rotation's check-in time is at or later than the configured commute-in threshold for its base.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Commute Home",
                        definition: "The rotation's calculated release is at or earlier than the configured commute-home threshold for its base and occurs after 03:00.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Fully Commutable",
                        definition: "The rotation satisfies both the Commute In and Commute Home rules.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Front-only Commutable",
                        definition: "The rotation satisfies the Commute In rule but not the Commute Home rule.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Back-only Commutable",
                        definition: "The rotation satisfies the Commute Home rule but not the Commute In rule.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Not Commutable",
                        definition: "The rotation satisfies neither the Commute In nor the Commute Home rule.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Commute Window",
                        definition: "The base-specific minimum check-in time and maximum release time used to classify rotations as commutable.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Credit and Pay",
                entries: [
                    GlossaryEntry(
                        term: "Total Credit",
                        definition: "The rotation's published TL value from the total-credit line, converted to hours and minutes.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Block Credit",
                        definition: "The published BL value representing scheduled block credit.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Non-block Credit",
                        definition: "Total credit minus block credit, with the result prevented from falling below zero.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Credit Per Day",
                        definition: "Total rotation credit divided by the rotation's number of days.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Synthetic Credit",
                        definition:
                            "The percentage of a rotation's total credit that is not produced by scheduled block time. It is calculated as 1 minus block divided by credit.",
                        example:
                            "A rotation with 20:00 of credit and 16:00 of block has 20% synthetic credit: 1 − (16 ÷ 20) = 0.20."
                    ),
                    GlossaryEntry(
                        term: "Duty Efficiency",
                        definition: "A measure comparing productive flying or credit with the amount of duty time required. Higher values generally indicate a more efficient rotation.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "TL",
                        definition: "The published total pay or total-credit value carried in the bidpacket data.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "SIT",
                        definition: "The published SIT pay value for the rotation. The app displays and filters the value as supplied in the bidpacket.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "EDP",
                        definition: "The published EDP pay value for the rotation. The app displays and filters the value as supplied in the bidpacket.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "HOL",
                        definition: "The published HOL pay value for the rotation. The app displays and filters the value as supplied in the bidpacket.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "CARVE",
                        definition: "The published CARVE pay value for the rotation. The app displays and filters the value as supplied in the bidpacket.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Rest and Recovery",
                entries: [
                    GlossaryEntry(
                        term: "Rest Window",
                        definition: "A recorded rest period between two consecutive duty periods. The app stores the rest length along with the FDP, block time, and number of legs before and after that rest.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "FDP Recovery",
                        definition: "Filters for a rest period at or below the selected length when the preceding duty period's FDP is at or above the selected threshold.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Block Recovery",
                        definition: "Filters for a rest period at or below the selected length when the preceding duty period's block time is at or above the selected threshold.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Legs Recovery",
                        definition: "Filters for a rest period at or below the selected length when the preceding duty period contains at least the selected number of legs.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Average Rest: No Red-eye/Circ-Swap",
                        definition: "The occurrence-weighted average of all recorded overnight rest periods on rotations containing neither a red-eye nor a circadian swap.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Average Rest: With Red-eye or Circ-Swap",
                        definition: "The occurrence-weighted average of all recorded overnight rest periods on rotations containing at least one red-eye or at least one circadian swap.",
                        example: nil
                    )
                ]
            ),

            GlossarySection(
                title: "Filters",
                entries: [
                    GlossaryEntry(
                        term: "Start Day",
                        definition: "Filters rotations by the weekday of their effective start dates.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Touches Dates",
                        definition: "Filters rotations according to whether any day spanned by the rotation overlaps a selected calendar date.",
                        example: "A 3-day rotation beginning August 10 touches August 10, 11, and 12."
                    ),
                    GlossaryEntry(
                        term: "Touches Weekend",
                        definition: "Filters rotations according to whether any of their effective operating dates fall on Saturday or Sunday.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Include",
                        definition: "Keeps rotations that touch at least one selected date.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Exclude",
                        definition: "Removes rotations that touch at least one selected date.",
                        example: nil
                    ),
                    GlossaryEntry(
                        term: "Between",
                        definition: "Keeps check-in or release times that fall inclusively between the two entered times.",
                        example: "Between 08:00 and 10:00 includes values at 08:00, 09:15, and 10:00."
                    ),
                    GlossaryEntry(
                        term: "Leg-heavy Days",
                        definition: "Keeps rotations containing at least the selected number of duty days with at least the selected number of legs.",
                        example: "At least 2 days with 4 or more legs."
                    ),
                    GlossaryEntry(
                        term: "Region",
                        definition: "Filters rotations by the geographic region associated with airports touched by the rotation.",
                        example: nil
                    )
                ]
            )
        ]
       
    

    static var allEntries: [GlossaryEntry] {
        sections.flatMap(\.entries)
    }

    
    static func entry(for term: String) -> GlossaryEntry? {
        allEntries.first {
            $0.term.compare(
                term,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }
    }
}
