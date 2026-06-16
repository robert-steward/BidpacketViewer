import SwiftUI

struct RotationCardView: View {
    let rotation: Rotation
    let isExpanded: Bool
    let isSelected: Bool
    let onToggleExpanded: () -> Void
    let onToggleSelected: () -> Void

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
        VStack(alignment: .leading, spacing: 6) {
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

                Text("•")
                    .foregroundStyle(.tertiary)

                Text("\(rotation.totalCredit?.hm ?? "—") Credit")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.tertiary)

                Text(startDateSummary)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

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
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let overnightSummary {
                infoPill(title: "Overnights", value: overnightSummary)
            }

            infoPill(title: "Start Dates", value: fullDateList)

            rawTextSection
        }
        .padding(.top, 4)
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
        let days = effectiveDayNumbers

        switch days.count {
        case 0:
            return "No dates"
        case 1:
            return "Jun \(days[0])"
        case 2:
            return "Jun \(days[0]), \(days[1])"
        case 3:
            return "Jun \(days[0]), \(days[1]), \(days[2])"
        default:
            return "\(days.count) starts"
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

    private var effectiveDayNumbers: [Int] {
        (rotation.effectiveDates ?? []).compactMap { dateString in
            let parts = dateString.split(separator: "-")
            return Int(parts.last ?? "")
        }
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

