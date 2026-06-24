//
//  FilterPanelView.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/17/26.
//

import SwiftUI

struct FilterPanelView: View {
    @Bindable var viewModel: BidpacketViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDateComponents: Set<DateComponents> = []
    
    

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tripSection
                    stationSection
                    creditSection
                    recoverySection
                    operationsSection
                    commutabilitySection
                    datesSection
                    extraPaySection
                }
                .padding(24)
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

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
        .frame(width: 820, height: 900)
    }

    
    private var extraPaySection: some View {
        filterGroup(title: "Extra Pay") {

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 14
            ) {

                minimumPayField(
                    title: "SIT ≥",
                    value: $viewModel.filters.sitPayMinimum
                )

                minimumPayField(
                    title: "EDP ≥",
                    value: $viewModel.filters.edpPayMinimum
                )

                minimumPayField(
                    title: "HOL ≥",
                    value: $viewModel.filters.holPayMinimum
                )

                minimumPayField(
                    title: "CARVE ≥",
                    value: $viewModel.filters.carvePayMinimum
                )
            }
        }
    }
    
    private func minimumPayField(
        title: String,
        value: Binding<Double?>
    ) -> some View {

        TextField(
            title,
            text: Binding(
                get: {
                    if let value = value.wrappedValue {
                        return String(format: "%.1f", value)
                    }

                    return ""
                },
                set: { newValue in
                    value.wrappedValue = Double(newValue)
                }
            )
        )
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
    }

    private var recoverySection: some View {
        filterGroup(title: "Recovery") {
            VStack(alignment: .leading, spacing: 18) {
                recoveryMinutesRow(
                    title: "FDP Recovery",
                    restMinutes: $viewModel.filters.fdpRecoveryRestMinutes,
                    triggerMinutes: $viewModel.filters.fdpRecoveryFDPMinutes,
                    triggerLabel: "after FDP ≥"
                )

                recoveryIntRow(
                    title: "Legs Recovery",
                    restMinutes: $viewModel.filters.legsRecoveryRestMinutes,
                    triggerValue: $viewModel.filters.legsRecoveryLegsBefore,
                    triggerLabel: "after legs ≥"
                )

                recoveryMinutesRow(
                    title: "Block Recovery",
                    restMinutes: $viewModel.filters.blockRecoveryRestMinutes,
                    triggerMinutes: $viewModel.filters.blockRecoveryBlockMinutes,
                    triggerLabel: "after block ≥"
                )
            }
        }
    }
    
    private func recoveryMinutesRow(
        title: String,
        restMinutes: Binding<Int?>,
        triggerMinutes: Binding<Int?>,
        triggerLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                Text("Rest ≤")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalHoursField(minutes: restMinutes)
                    .frame(width: 80)

                Text("hh")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalMinutesRemainderField(minutes: restMinutes)
                    .frame(width: 80)

                Text("mm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(triggerLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)

                optionalHoursField(minutes: triggerMinutes)
                    .frame(width: 80)

                Text("hh")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalMinutesRemainderField(minutes: triggerMinutes)
                    .frame(width: 80)

                Text("mm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    private func recoveryIntRow(
        title: String,
        restMinutes: Binding<Int?>,
        triggerValue: Binding<Int?>,
        triggerLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                Text("Rest ≤")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalHoursField(minutes: restMinutes)
                    .frame(width: 80)

                Text("hh")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalMinutesRemainderField(minutes: restMinutes)
                    .frame(width: 80)

                Text("mm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(triggerLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)

                optionalIntField(
                    placeholder: "#",
                    value: triggerValue
                )
                .frame(width: 90)

                Spacer()
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Redeye")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Redeye", selection: $viewModel.filters.redeyeFilterMode) {
                        ForEach(RedeyeFilterMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                toggleChip("Day Layover", isOn: $viewModel.filters.dayLayoverOnly)
                toggleChip("Cross-town", isOn: $viewModel.filters.crossTownOnly)
                toggleChip("Starts DH", isOn: $viewModel.filters.startsDeadheadOnly)
                toggleChip("Ends DH", isOn: $viewModel.filters.endsDeadheadOnly)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Circadian swaps")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Picker("Circadian swaps", selection: $viewModel.filters.circadianSwapMode) {
                        ForEach(CircadianSwapFilterMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Mitigation", selection: $viewModel.filters.circadianMitigationMode) {
                        ForEach(CircadianMitigationFilterMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
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

    private var stationSection: some View {
        filterGroup(title: "Stations") {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 220), spacing: 14)
                ],
                spacing: 14
            ) {
                labeledTextField(
                    title: "Check-in Station",
                    placeholder: "e.g. LAX",
                    text: $viewModel.filters.checkInStationText
                )

                labeledTextField(
                    title: "Overnight Station",
                    placeholder: "e.g. BOS",
                    text: $viewModel.filters.overnightStationText
                )

                labeledTextField(
                    title: "Touches Station",
                    placeholder: "e.g. ATL",
                    text: $viewModel.filters.touchesStationText
                )
            }
        }
    }


    private var tripSection: some View {
        filterGroup(title: "Trip") {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    dayChip(1, title: "1 Day")
                    dayChip(2, title: "2 Day")
                    dayChip(3, title: "3 Day")
                    dayChip(4, title: "4 Day")
                    dayChip(5, title: "5+ Day")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Start Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        startDayChip("Mon")
                        startDayChip("Tue")
                        startDayChip("Wed")
                        startDayChip("Thu")
                        startDayChip("Fri")
                        startDayChip("Sat")
                        startDayChip("Sun")
                    }
                }
                
                

                Picker("Weekend Touch", selection: $viewModel.filters.weekendTouchMode) {
                    ForEach(WeekendTouchFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                comparisonIntRow(
                    title: "Duty Periods",
                    mode: $viewModel.filters.dutyPeriodsMode,
                    value: $viewModel.filters.dutyPeriodsValue,
                    placeholder: "#"
                )

                comparisonIntRow(
                    title: "Max Legs",
                    mode: $viewModel.filters.maxLegsMode,
                    value: $viewModel.filters.maxLegsValue,
                    placeholder: "#"
                )
                

                comparisonIntRow(
                    title: "Frequency",
                    mode: $viewModel.filters.frequencyMode,
                    value: $viewModel.filters.frequencyValue,
                    placeholder: "#"
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Leg-heavy Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Text("At least")

                        optionalIntField(
                            placeholder: "Days",
                            value: $viewModel.filters.daysWithLegsDaysValue
                        )
                        .frame(width: 90)

                        Text("days with")

                        optionalIntField(
                            placeholder: "Legs",
                            value: $viewModel.filters.daysWithLegsLegsValue
                        )
                        .frame(width: 90)

                        Text("or more legs")

                        Spacer()
                    }
                }
                
                comparisonMinutesRow(
                    title: "Check-in",
                    mode: $viewModel.filters.checkInMode,
                    minutes: $viewModel.filters.checkInMinutes
                )

                comparisonMinutesRow(
                    title: "Release",
                    mode: $viewModel.filters.releaseMode,
                    minutes: $viewModel.filters.releaseMinutes
                )
                
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 220), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    labeledTextField(
                        title: "Base",
                        placeholder: "e.g. LAX",
                        text: $viewModel.filters.selectedBase
                    )

                    labeledTextField(
                        title: "Position",
                        placeholder: "e.g. A",
                        text: $viewModel.filters.selectedPosition
                    )
                }
            }
        }
    }

    private func startDayChip(_ day: String) -> some View {
        let selected = viewModel.filters.selectedStartDays.contains(day)

        return Button {
            if selected {
                viewModel.filters.selectedStartDays.remove(day)
            } else {
                viewModel.filters.selectedStartDays.insert(day)
            }
        } label: {
            Text(day)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(selected ? .blue : Color(.systemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    private var creditSection: some View {
        filterGroup(title: "Credit / Time") {
            VStack(alignment: .leading, spacing: 18) {
                comparisonMinutesRow(
                    title: "Total Credit",
                    mode: $viewModel.filters.totalCreditMode,
                    minutes: $viewModel.filters.totalCreditMinutes
                )

                comparisonMinutesRow(
                    title: "Credit Per Day",
                    mode: $viewModel.filters.creditPerDayMode,
                    minutes: $viewModel.filters.creditPerDayMinutes
                )

                comparisonMinutesRow(
                    title: "Non-block Credit",
                    mode: $viewModel.filters.nonBlockCreditMode,
                    minutes: $viewModel.filters.nonBlockCreditMinutes
                )

                comparisonMinutesRow(
                    title: "TAFB",
                    mode: $viewModel.filters.tafbMode,
                    minutes: $viewModel.filters.tafbMinutes
                )
                comparisonDoubleRow(
                    title: "Duty Efficiency",
                    mode: $viewModel.filters.dutyEfficiencyMode,
                    value: $viewModel.filters.dutyEfficiencyValue,
                    placeholder: "0.85"
                )

                comparisonMinutesRow(
                    title: "Longest FDP",
                    mode: $viewModel.filters.longestFDPMode,
                    minutes: $viewModel.filters.longestFDPMinutes
                )
                
                plainMinutesRow(
                    title: "Longest Sit ≥",
                    minutes: $viewModel.filters.longestSitMinutes
                )

                rangeMinutesRow(
                    title: "Layover Length",
                    minMinutes: $viewModel.filters.layoverLengthMinMinutes,
                    maxMinutes: $viewModel.filters.layoverLengthMaxMinutes
                )
            }
        }
    }
    
    private func plainMinutesRow(
        title: String,
        minutes: Binding<Int?>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 150, alignment: .leading)

            optionalHoursField(minutes: minutes)
                .frame(width: 80)

            Text("hh")
                .font(.caption)
                .foregroundStyle(.secondary)

            optionalMinutesRemainderField(minutes: minutes)
                .frame(width: 80)

            Text("mm")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func rangeMinutesRow(
        title: String,
        minMinutes: Binding<Int?>,
        maxMinutes: Binding<Int?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                Text("Min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalHoursField(minutes: minMinutes)
                    .frame(width: 80)

                Text("hh")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalMinutesRemainderField(minutes: minMinutes)
                    .frame(width: 80)

                Text("mm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Max")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)

                optionalHoursField(minutes: maxMinutes)
                    .frame(width: 80)

                Text("hh")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalMinutesRemainderField(minutes: maxMinutes)
                    .frame(width: 80)

                Text("mm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
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

                TextField(
                    "YYYY-MM-DD, YYYY-MM-DD",
                    text: Binding(
                        get: {
                            viewModel.filters.touchDateStrings
                                .sorted()
                                .joined(separator: ", ")
                        },
                        set: { newValue in
                            let dates = newValue
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }

                            viewModel.filters.touchDateStrings = Set(dates)
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                Text("Enter one or more dates separated by commas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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

    private func labeledTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private func comparisonDoubleRow(
        title: String,
        mode: Binding<ComparisonFilterMode>,
        value: Binding<Double?>,
        placeholder: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(ComparisonFilterMode.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            TextField(
                placeholder,
                text: Binding(
                    get: {
                        if let wrapped = value.wrappedValue {
                            return String(format: "%.3f", wrapped)
                        }

                        return ""
                    },
                    set: { newValue in
                        value.wrappedValue = Double(newValue)
                    }
                )
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 100)

            Spacer()
        }
    }

    private func comparisonIntRow(
        title: String,
        mode: Binding<ComparisonFilterMode>,
        value: Binding<Int?>,
        placeholder: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(ComparisonFilterMode.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            optionalIntField(
                placeholder: placeholder,
                value: value
            )
            .frame(width: 90)

            Spacer()
        }
    }

    private func comparisonMinutesRow(
        title: String,
        mode: Binding<ComparisonFilterMode>,
        minutes: Binding<Int?>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(ComparisonFilterMode.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            optionalHoursField(minutes: minutes)
                .frame(width: 80)

            Text("hh")
                .font(.caption)
                .foregroundStyle(.secondary)

            optionalMinutesRemainderField(minutes: minutes)
                .frame(width: 80)

            Text("mm")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func optionalIntField(
        placeholder: String,
        value: Binding<Int?>
    ) -> some View {
        TextField(
            placeholder,
            text: Binding(
                get: {
                    if let wrapped = value.wrappedValue {
                        return "\(wrapped)"
                    }

                    return ""
                },
                set: { newValue in
                    value.wrappedValue = Int(newValue)
                }
            )
        )
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
    }

    private func optionalHoursField(
        minutes: Binding<Int?>
    ) -> some View {
        TextField(
            "hh",
            text: Binding(
                get: {
                    guard let total = minutes.wrappedValue else {
                        return ""
                    }

                    return "\(total / 60)"
                },
                set: { newValue in
                    let hours = Int(newValue) ?? 0
                    let currentRemainder = (minutes.wrappedValue ?? 0) % 60
                    minutes.wrappedValue = hours * 60 + currentRemainder
                }
            )
        )
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
    }

    private func optionalMinutesRemainderField(
        minutes: Binding<Int?>
    ) -> some View {
        TextField(
            "mm",
            text: Binding(
                get: {
                    guard let total = minutes.wrappedValue else {
                        return ""
                    }

                    return "\(total % 60)"
                },
                set: { newValue in
                    let remainder = Int(newValue) ?? 0
                    let currentHours = (minutes.wrappedValue ?? 0) / 60
                    minutes.wrappedValue = currentHours * 60 + remainder
                }
            )
        )
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
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
