import SwiftUI

struct RotationCardView: View {
    let rotation: Rotation
    let selectedSorts: [RotationSortOption]
    let isExpanded: Bool
    let isSelected: Bool
    let onToggleExpanded: () -> Void
    let onToggleSelected: () -> Void
    @AppStorage("showRedeyeBadge") private var showRedeyeBadge = true
    @AppStorage("showDayLayoverBadge") private var showDayLayoverBadge = true
    @AppStorage("showCrossTownBadge") private var showCrossTownBadge = true
    @AppStorage("showDeadheadBadge") private var showDeadheadBadge = true
    @AppStorage("showCommutabilityBadge") private var showCommutabilityBadge = true
    @AppStorage("showLegsBadge") private var showLegsBadge = true
    @AppStorage("showLongFDPBadge") private var showLongFDPBadge = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    onToggleExpanded()
                }
            } label: {
                collapsedContent
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var collapsedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                Button {
                    onToggleSelected()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)

                Text(rotation.rotationNumber)
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 88, alignment: .leading)

                Text(dayText)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                separatorDot

                Text("\(rotation.totalCredit?.hm ?? "—") Credit")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                separatorDot

                Text(startDateSummary)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                infoBadgeLine

                Spacer()

                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            scoreStrip

            if let overnightSummary {
                Text(overnightSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.leading, 136)
            }
        }
        .contentShape(Rectangle())
    }

    private var scoreStrip: some View {
        HStack(spacing: 8) {
            scorePill(title: "Final", value: rotation.finalScore)

            ForEach(collapsedScoreItems, id: \.title) { item in
                scorePill(title: item.title, value: item.value)
            }
        }
        .padding(.leading, 136)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            fullScoreBreakdown

            if let overnightSummary {
                infoPill(title: "Overnights", value: overnightSummary)
            }

            if !infoBadges.isEmpty {
                infoPill(title: "Flags", value: infoBadges.joined(separator: "  "))
            }

            infoPill(title: "Start Dates", value: fullDateList)

            rawTextSection
        }
        .padding(.top, 4)
    }

    private var fullScoreBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scores")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 140), spacing: 8)
                ],
                alignment: .leading,
                spacing: 8
            ) {
                scorePill(title: "Final", value: rotation.finalScore)
                scorePill(title: "Legs", value: rotation.scoreParts?.legsScore)
                scorePill(title: "Rest", value: rotation.scoreParts?.restScore)
                scorePill(title: "In", value: rotation.scoreParts?.inScore)
                scorePill(title: "Out", value: rotation.scoreParts?.outScore)
                scorePill(title: "WOCL", value: rotation.scoreParts?.woclScore)
                scorePill(title: "FDP / Max", value: rotation.scoreParts?.fdpOverMaxFDP)
                scorePill(title: "Block / FDP", value: rotation.scoreParts?.blockOverFDP)
                scorePill(title: "Block / Max", value: rotation.scoreParts?.blockOverMaxBlock)
                scorePill(title: "Circadian", value: rotation.scoreParts?.cirSwapScore)
                scorePill(title: "Turn", value: rotation.scoreParts?.turnScore)
                scorePill(title: "Commute", value: rotation.scoreParts?.commutabilityScore)
                scorePill(title: "Pay / TAFB", value: rotation.scoreParts?.payTafbScore)
                scorePill(title: "DH", value: rotation.scoreParts?.dhScore)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var collapsedScoreItems: [(title: String, value: Double?)] {
        selectedSorts
            .filter { $0 != .rotationNumber && $0 != .days && $0 != .finalScore }
            .compactMap { scoreItem(for: $0) }
    }

    private func scoreItem(for option: RotationSortOption) -> (title: String, value: Double?)? {
        switch option {
        case .rotationNumber, .days:
            return nil
        case .finalScore:
            return ("Final", rotation.finalScore)
        case .legsScore:
            return ("Legs", rotation.scoreParts?.legsScore)
        case .restScore:
            return ("Rest", rotation.scoreParts?.restScore)
        case .inScore:
            return ("In", rotation.scoreParts?.inScore)
        case .outScore:
            return ("Out", rotation.scoreParts?.outScore)
        case .woclScore:
            return ("WOCL", rotation.scoreParts?.woclScore)
        case .fdpOverMaxFDP:
            return ("FDP/Max", rotation.scoreParts?.fdpOverMaxFDP)
        case .blockOverFDP:
            return ("Blk/FDP", rotation.scoreParts?.blockOverFDP)
        case .blockOverMaxBlock:
            return ("Blk/Max", rotation.scoreParts?.blockOverMaxBlock)
        case .circadianSwapScore:
            return ("Circadian", rotation.scoreParts?.cirSwapScore)
        case .turnScore:
            return ("Turn", rotation.scoreParts?.turnScore)
        case .commutabilityScore:
            return ("Commute", rotation.scoreParts?.commutabilityScore)
        case .payTafbScore:
            return ("Pay/TAFB", rotation.scoreParts?.payTafbScore)
        case .dhScore:
            return ("DH", rotation.scoreParts?.dhScore)
        }
    }

    private func scorePill(title: String, value: Double?) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formatScore(value))
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(Capsule())
    }

    private func formatScore(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f", value)
    }

    private var rawTextSection: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Text(rotation.rawChunkText ?? "No text available.")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .lineSpacing(2)
                .textSelection(.enabled)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var infoBadgeLine: some View {
        HStack(spacing: 6) {
            ForEach(infoBadges.prefix(4), id: \.self) { badge in
                Text(badge)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if infoBadges.count > 4 {
                Text("+\(infoBadges.count - 4)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private var separatorDot: some View {
        Text("•")
            .foregroundStyle(.tertiary)
    }

    private func infoPill(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var infoBadges: [String] {
        var badges: [String] = []

        if showRedeyeBadge, (rotation.numRedeyes ?? 0) > 0 {
            badges.append("🌙 Red-eye")
        }

        if showDayLayoverBadge, (rotation.dayLayovers ?? 0) > 0 {
            badges.append("🏨 Day Layover")
        }

        if showCrossTownBadge, (rotation.xtownLayover ?? 0) > 0 {
            badges.append("🚕 Cross-town")
        }

        if showDeadheadBadge {
            if rotation.frontDH == true && rotation.backDH == true {
                badges.append("🚌 Front/Back DH")
            } else if rotation.frontDH == true {
                badges.append("🚌 Front DH")
            } else if rotation.backDH == true {
                badges.append("🚌 Back DH")
            }
        }

        if showCommutabilityBadge {
            if rotation.fullyCommutable == true {
                badges.append("✅ Full")
            } else if rotation.frontCommutable == true {
                badges.append("⬆️ Front")
            } else if rotation.backCommutable == true {
                badges.append("⬇️ Back")
            }
        }

        if showLegsBadge, let maxLegs = rotation.maxLegs, maxLegs >= 4 {
            badges.append("🦵 \(maxLegs) Legs")
        }

        if showLongFDPBadge, let longestFDP = rotation.longestFDP?.minutes, longestFDP >= 720 {
            badges.append("⏱️ 12+ FDP")
        }

        return badges
    }
    
    private var dayText: String {
        let days = rotation.numDays ?? 0
        return days == 1 ? "1 Day" : "\(days) Days"
    }

    private var overnightSummary: String? {
        guard let overnights = rotation.overnights,
              !overnights.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return overnights
    }

    private var startDateSummary: String {
        let dates = rotation.effectiveDates ?? []

        switch dates.count {
        case 0:
            return "No dates"

        case 1:
            return formatDate(dates[0])

        case 2:
            return compactDateSummary(dates)

        case 3:
            return compactDateSummary(dates)

        default:
            return "\(dates.count) starts"
        }
    }
    
    private var fullDateList: String {
        let dates = rotation.effectiveDates ?? []

        if dates.isEmpty {
            return "No start dates available"
        }

        return dates
            .map { formatDate($0) }
            .joined(separator: ", ")
    }

//    private var effectiveDayNumbers: [Int] {
//        (rotation.effectiveDates ?? []).compactMap { dateString in
//            let parts = dateString.split(separator: "-")
//            return Int(parts.last ?? "")
//        }
//    }

    private func compactDateSummary(_ dateStrings: [String]) -> String {
        let parsed = dateStrings.compactMap { dateString -> (month: Int, day: Int)? in
            let parts = dateString.split(separator: "-")

            guard parts.count == 3,
                  let month = Int(parts[1]),
                  let day = Int(parts[2]),
                  month >= 1,
                  month <= 12 else {
                return nil
            }

            return (month, day)
        }

        guard !parsed.isEmpty else {
            return dateStrings.joined(separator: ", ")
        }

        let allSameMonth = parsed.allSatisfy {
            $0.month == parsed[0].month
        }

        if allSameMonth {
            let monthName = Calendar.current.shortMonthSymbols[parsed[0].month - 1]
            let days = parsed.map { String($0.day) }.joined(separator: ", ")
            return "\(monthName) \(days)"
        }

        return dateStrings
            .map { formatDate($0) }
            .joined(separator: ", ")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let parts = dateString.split(separator: "-")

        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              month >= 1,
              month <= 12 else {
            return dateString
        }

        let monthName = Calendar.current.shortMonthSymbols[month - 1]
        return "\(monthName) \(day)"
    }
}
