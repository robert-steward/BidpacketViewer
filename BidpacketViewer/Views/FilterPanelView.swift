//
//  FilterPanelView.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/17/26.
//
import SwiftUI

struct FilterPanelView: View {
    @Bindable var viewModel: BidpacketViewModel

    @State private var selectedDateComponents: Set<DateComponents> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    daysSection
                    operationsSection
                    commutabilitySection
                    datesSection
                }
                .padding(24)
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        selectedDateComponents.removeAll()
                        viewModel.filters.clearAll()
                    }
                    .disabled(!viewModel.filters.hasActiveFilters)
                }
            }
            .onAppear {
                selectedDateComponents = dateComponentsFromFilterStrings()
            }
        }
        .frame(minWidth: 520, minHeight: 650)
    }

    private var daysSection: some View {
        filterGroup(title: "Trip Length") {
            HStack(spacing: 10) {
                dayChip(1, title: "1 Day")
                dayChip(2, title: "2 Day")
                dayChip(3, title: "3 Day")
                dayChip(4, title: "4 Day")
                dayChip(5, title: "5+ Day")
            }
        }
    }

    private var operationsSection: some View {
        filterGroup(title: "Operations") {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 10)
                ],
                spacing: 10
            ) {
                toggleChip("Red-eye", isOn: $viewModel.filters.redEyeOnly)
                toggleChip("Day Layover", isOn: $viewModel.filters.dayLayoverOnly)
                toggleChip("Cross-town", isOn: $viewModel.filters.crossTownOnly)
                toggleChip("Starts DH", isOn: $viewModel.filters.startsDeadheadOnly)
                toggleChip("Ends DH", isOn: $viewModel.filters.endsDeadheadOnly)
            }
        }
    }

    private var commutabilitySection: some View {
        filterGroup(title: "Commutability") {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 170), spacing: 10)
                ],
                spacing: 10
            ) {
                toggleChip("Commute In", isOn: $viewModel.filters.commuteInOnly)
                toggleChip("Commute Home", isOn: $viewModel.filters.commuteHomeOnly)
                toggleChip("Fully Commutable", isOn: $viewModel.filters.fullyCommutableOnly)
            }
        }
    }

    private var datesSection: some View {
        filterGroup(title: "Touches Dates") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Date Mode", selection: $viewModel.filters.touchDateMode) {
                    ForEach(TouchDateFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                MultiDatePicker(
                    "Select dates",
                    selection: $selectedDateComponents
                )
                .onChange(of: selectedDateComponents) { _, newValue in
                    viewModel.filters.touchDateStrings = Set(
                        newValue.compactMap { dateString(from: $0) }
                    )
                }

                if !viewModel.filters.touchDateStrings.isEmpty {
                    Text("\(viewModel.filters.touchDateStrings.count) dates selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func filterGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func toggleChip(
        _ title: String,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isOn.wrappedValue ? .blue.opacity(0.16) : Color(.systemBackground))
            .foregroundStyle(isOn.wrappedValue ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func dayChip(_ days: Int, title: String) -> some View {
        let selected = isDayLengthSelected(days)

        return Button {
            toggleDayLength(days)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(selected ? .blue : Color(.systemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggleDayLength(_ days: Int) {
        if days == 5 {
            toggleFivePlusDayLength()
            return
        }

        if viewModel.filters.selectedDayLengths.contains(days) {
            viewModel.filters.selectedDayLengths.remove(days)
        } else {
            viewModel.filters.selectedDayLengths.insert(days)
        }
    }

    private func toggleFivePlusDayLength() {
        let fivePlus = Set([5, 6, 7, 8, 9, 10])

        if !viewModel.filters.selectedDayLengths.isDisjoint(with: fivePlus) {
            viewModel.filters.selectedDayLengths.subtract(fivePlus)
        } else {
            viewModel.filters.selectedDayLengths.formUnion(fivePlus)
        }
    }

    private func isDayLengthSelected(_ days: Int) -> Bool {
        if days == 5 {
            return viewModel.filters.selectedDayLengths.contains { $0 >= 5 }
        }

        return viewModel.filters.selectedDayLengths.contains(days)
    }

    private func dateString(from components: DateComponents) -> String? {
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func dateComponentsFromFilterStrings() -> Set<DateComponents> {
        Set(
            viewModel.filters.touchDateStrings.compactMap { string in
                let parts = string.split(separator: "-").compactMap { Int($0) }

                guard parts.count == 3 else {
                    return nil
                }

                return DateComponents(
                    calendar: Calendar.current,
                    year: parts[0],
                    month: parts[1],
                    day: parts[2]
                )
            }
        )
    }
}

#Preview {
    FilterPanelView(viewModel: BidpacketViewModel())
}
