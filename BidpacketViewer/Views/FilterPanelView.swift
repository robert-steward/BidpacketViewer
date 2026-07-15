//
//  FilterPanelView.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/17/26.
//

import SwiftUI

private let availableRegions = [
    "Domestic",
    "Hawaii",
    "Alaska",
    "Canada",
    "Mexico/Caribbean",
    "Caribbean",
    "Europe",
    "Pacific",
    "South America",
    "Africa",
    "Middle East"
]

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
        .frame(width: 820)
        .frame(maxHeight: 5000)
    }

    // MARK: - Trip

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
                    filterLabel("Start Day", glossaryTerm: "Start Day")

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

                VStack(alignment: .leading, spacing: 8) {
                    filterLabel(
                        "Weekend Touch",
                        glossaryTerm: "Touches Weekend",
                        font: .subheadline.weight(.semibold),
                        secondary: false
                    )

                    Picker(
                        "Weekend Touch",
                        selection: $viewModel.filters.weekendTouchMode
                    ) {
                        ForEach(WeekendTouchFilterMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                comparisonIntRow(
                    title: "Duty Periods",
                    glossaryTerm: "Duty Period",
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
                    glossaryTerm: "Frequency",
                    mode: $viewModel.filters.frequencyMode,
                    value: $viewModel.filters.frequencyValue,
                    placeholder: "#"
                )

                VStack(alignment: .leading, spacing: 10) {
                    filterLabel(
                        "Leg-heavy Days",
                        glossaryTerm: "Leg-heavy Days"
                    )

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

                dailyBlockFilterRow

                comparisonMinutesRangeRow(
                    title: "Check-in",
                    glossaryTerm: "Check-in",
                    mode: $viewModel.filters.checkInMode,
                    startMinutes: $viewModel.filters.checkInMinutes,
                    endMinutes: $viewModel.filters.checkInEndMinutes
                )

                comparisonMinutesRangeRow(
                    title: "Release",
                    glossaryTerm: "Release",
                    mode: $viewModel.filters.releaseMode,
                    startMinutes: $viewModel.filters.releaseMinutes,
                    endMinutes: $viewModel.filters.releaseEndMinutes
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

    private var dailyBlockFilterRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            filterLabel(
                "Daily Block",
                glossaryTerm: "Daily Block Filter"
            )

            HStack(spacing: 12) {
                Text("At least")

                optionalIntField(
                    placeholder: "Days",
                    value: $viewModel.filters.blockDaysRequired
                )
                .frame(width: 90)

                Text("days")

                Picker(
                    "Daily Block Comparison",
                    selection: $viewModel.filters.blockDaysMode
                ) {
                    ForEach(DailyBlockComparisonMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                optionalHoursField(
                    minutes: $viewModel.filters.blockDaysThresholdMinutes
                )
                .frame(width: 80)

                Text("hh")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalMinutesRemainderField(
                    minutes: $viewModel.filters.blockDaysThresholdMinutes
                )
                .frame(width: 80)

                Text("mm block")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    // MARK: - Stations

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
                    glossaryTerm: "Touches Station",
                    placeholder: "e.g. ATL",
                    text: $viewModel.filters.touchesStationText
                )

                VStack(alignment: .leading, spacing: 8) {
                    filterLabel(
                        "Regions",
                        glossaryTerm: "Region",
                        font: .headline,
                        secondary: false
                    )

                    Menu {
                        ForEach(availableRegions, id: \.self) { region in
                            Button {
                                toggleRegion(region)
                            } label: {
                                if viewModel.filters.selectedRegions.contains(region) {
                                    Label(region, systemImage: "checkmark")
                                } else {
                                    Text(region)
                                }
                            }
                        }

                        if !viewModel.filters.selectedRegions.isEmpty {
                            Divider()

                            Button("Clear Regions", role: .destructive) {
                                viewModel.filters.selectedRegions.removeAll()
                            }
                        }
                    } label: {
                        HStack {
                            Text(regionMenuTitle)
                                .foregroundStyle(
                                    viewModel.filters.selectedRegions.isEmpty
                                        ? .secondary
                                        : .primary
                                )

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var regionMenuTitle: String {
        if viewModel.filters.selectedRegions.isEmpty {
            return "Any region"
        }

        let selected = viewModel.filters.selectedRegions.sorted()

        if selected.count <= 2 {
            return selected.joined(separator: ", ")
        }

        return "\(selected.count) regions selected"
    }

    private func toggleRegion(_ region: String) {
        if viewModel.filters.selectedRegions.contains(region) {
            viewModel.filters.selectedRegions.remove(region)
        } else {
            viewModel.filters.selectedRegions.insert(region)
        }
    }

    // MARK: - Credit / Time

    private var creditSection: some View {
        filterGroup(title: "Credit / Time") {
            VStack(alignment: .leading, spacing: 18) {
                comparisonMinutesRow(
                    title: "Total Credit",
                    glossaryTerm: "Total Credit",
                    mode: $viewModel.filters.totalCreditMode,
                    minutes: $viewModel.filters.totalCreditMinutes
                )

                comparisonMinutesRow(
                    title: "Credit Per Day",
                    glossaryTerm: "Credit Per Day",
                    mode: $viewModel.filters.creditPerDayMode,
                    minutes: $viewModel.filters.creditPerDayMinutes
                )

                comparisonMinutesRow(
                    title: "Non-block Credit",
                    glossaryTerm: "Non-block Credit",
                    mode: $viewModel.filters.nonBlockCreditMode,
                    minutes: $viewModel.filters.nonBlockCreditMinutes
                )

                comparisonMinutesRow(
                    title: "TAFB",
                    glossaryTerm: "TAFB",
                    mode: $viewModel.filters.tafbMode,
                    minutes: $viewModel.filters.tafbMinutes
                )

                comparisonDoubleRow(
                    title: "Duty Efficiency",
                    glossaryTerm: "Duty Efficiency",
                    mode: $viewModel.filters.dutyEfficiencyMode,
                    value: $viewModel.filters.dutyEfficiencyValue,
                    placeholder: "0.85"
                )

                comparisonMinutesRow(
                    title: "Longest FDP",
                    glossaryTerm: "Longest FDP",
                    mode: $viewModel.filters.longestFDPMode,
                    minutes: $viewModel.filters.longestFDPMinutes
                )

                plainMinutesRow(
                    title: "Longest Sit ≥",
                    glossaryTerm: "Sit",
                    minutes: $viewModel.filters.longestSitMinutes
                )

                rangeMinutesRow(
                    title: "Layover Length",
                    glossaryTerm: "Layover Length",
                    minMinutes: $viewModel.filters.layoverLengthMinMinutes,
                    maxMinutes: $viewModel.filters.layoverLengthMaxMinutes
                )
            }
        }
    }

    // MARK: - Recovery

    private var recoverySection: some View {
        filterGroup(title: "Recovery") {
            VStack(alignment: .leading, spacing: 18) {
                recoveryMinutesRow(
                    title: "FDP Recovery",
                    glossaryTerm: "FDP Recovery",
                    restMinutes: $viewModel.filters.fdpRecoveryRestMinutes,
                    triggerMinutes: $viewModel.filters.fdpRecoveryFDPMinutes,
                    triggerLabel: "after FDP ≥"
                )

                recoveryIntRow(
                    title: "Legs Recovery",
                    glossaryTerm: "Legs Recovery",
                    restMinutes: $viewModel.filters.legsRecoveryRestMinutes,
                    triggerValue: $viewModel.filters.legsRecoveryLegsBefore,
                    triggerLabel: "after legs ≥"
                )

                recoveryMinutesRow(
                    title: "Block Recovery",
                    glossaryTerm: "Block Recovery",
                    restMinutes: $viewModel.filters.blockRecoveryRestMinutes,
                    triggerMinutes: $viewModel.filters.blockRecoveryBlockMinutes,
                    triggerLabel: "after block ≥"
                )
            }
        }
    }

    // MARK: - Operations

    private var operationsSection: some View {
        filterGroup(title: "Operations") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    filterLabel(
                        "Red-eye",
                        glossaryTerm: "Red-eye"
                    )

                    Picker(
                        "Red-eye",
                        selection: $viewModel.filters.redeyeFilterMode
                    ) {
                        ForEach(RedeyeFilterMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    toggleChip(
                        "Day Layover",
                        glossaryTerm: "Day Layover",
                        isOn: $viewModel.filters.dayLayoverOnly
                    )

                    toggleChip(
                        "Cross-town",
                        glossaryTerm: "Cross-town Layover",
                        isOn: $viewModel.filters.crossTownOnly
                    )

                    toggleChip(
                        "Starts DH",
                        glossaryTerm: "Front Deadhead",
                        isOn: $viewModel.filters.startsDeadheadOnly
                    )

                    toggleChip(
                        "Ends DH",
                        glossaryTerm: "Back Deadhead",
                        isOn: $viewModel.filters.endsDeadheadOnly
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    filterLabel(
                        "Circadian Swaps",
                        glossaryTerm: "Circadian Swap"
                    )

                    HStack(spacing: 10) {
                        Picker(
                            "Circadian Swaps",
                            selection: $viewModel.filters.circadianSwapMode
                        ) {
                            ForEach(CircadianSwapFilterMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack(spacing: 6) {
                            Picker(
                                "Mitigation",
                                selection: $viewModel.filters.circadianMitigationMode
                            ) {
                                ForEach(CircadianMitigationFilterMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)

                            GlossaryInfoButton(
                                term: "Mitigated Circadian Swap"
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Commutability

    private var commutabilitySection: some View {
        filterGroup(title: "Commutability") {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 170), spacing: 10)
                ],
                spacing: 10
            ) {
                toggleChip(
                    "Commute In",
                    glossaryTerm: "Commute In",
                    isOn: $viewModel.filters.commuteInOnly
                )

                toggleChip(
                    "Commute Home",
                    glossaryTerm: "Commute Home",
                    isOn: $viewModel.filters.commuteHomeOnly
                )

                toggleChip(
                    "Fully Commutable",
                    glossaryTerm: "Fully Commutable",
                    isOn: $viewModel.filters.fullyCommutableOnly
                )
            }
        }
    }

    // MARK: - Dates

    private var datesSection: some View {
        filterGroup(
            title: "Touches Dates",
            glossaryTerm: "Touches Dates"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Picker(
                    "Date Mode",
                    selection: $viewModel.filters.touchDateMode
                ) {
                    ForEach(TouchDateFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                HStack {
                    Spacer()

                    BidpacketMultiDateCalendar(
                        selectedDates: $selectedDateComponents,
                        initialVisibleMonth: viewModel.bidpacketMonthComponents
                    )
                    .frame(width: 430, height: 360)
                    .clipped()

                    Spacer()
                }

                HStack {
                    if selectedDateComponents.isEmpty {
                        Text("Select one or more dates.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(
                            "\(selectedDateComponents.count) " +
                            (selectedDateComponents.count == 1
                                ? "date selected"
                                : "dates selected")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !selectedDateComponents.isEmpty {
                        Button("Clear Dates", role: .destructive) {
                            selectedDateComponents.removeAll()
                            viewModel.filters.touchDateStrings.removeAll()
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
            }
            .onChange(of: selectedDateComponents) { _, newDates in
                viewModel.filters.touchDateStrings = Set(
                    newDates.compactMap { dateString(from: $0) }
                )
            }
        }
    }

    // MARK: - Extra Pay

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
                    glossaryTerm: "SIT",
                    value: $viewModel.filters.sitPayMinimum
                )

                minimumPayField(
                    title: "EDP ≥",
                    glossaryTerm: "EDP",
                    value: $viewModel.filters.edpPayMinimum
                )

                minimumPayField(
                    title: "HOL ≥",
                    glossaryTerm: "HOL",
                    value: $viewModel.filters.holPayMinimum
                )

                minimumPayField(
                    title: "CARVE ≥",
                    glossaryTerm: "CARVE",
                    value: $viewModel.filters.carvePayMinimum
                )
            }
        }
    }

    // MARK: - Reusable Rows

    private func filterGroup<Content: View>(
        title: String,
        glossaryTerm: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .headline,
                secondary: false
            )

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func filterLabel(
        _ title: String,
        glossaryTerm: String? = nil,
        font: Font = .caption,
        secondary: Bool = true
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(font)
                .foregroundStyle(secondary ? .secondary : .primary)

            if let glossaryTerm {
                GlossaryInfoButton(term: glossaryTerm)
            }
        }
    }

    private func comparisonIntRow(
        title: String,
        glossaryTerm: String? = nil,
        mode: Binding<ComparisonFilterMode>,
        value: Binding<Int?>,
        placeholder: String
    ) -> some View {
        HStack(spacing: 12) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )
            .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(standardComparisonModes) { option in
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

    private func comparisonDoubleRow(
        title: String,
        glossaryTerm: String? = nil,
        mode: Binding<ComparisonFilterMode>,
        value: Binding<Double?>,
        placeholder: String
    ) -> some View {
        HStack(spacing: 12) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )
            .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(standardComparisonModes) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            TextField(
                placeholder,
                text: Binding(
                    get: {
                        guard let wrapped = value.wrappedValue else {
                            return ""
                        }

                        return String(format: "%.3f", wrapped)
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

    private func comparisonMinutesRow(
        title: String,
        glossaryTerm: String? = nil,
        mode: Binding<ComparisonFilterMode>,
        minutes: Binding<Int?>
    ) -> some View {
        HStack(spacing: 12) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )
            .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(standardComparisonModes) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            optionalHoursField(minutes: minutes)
                .frame(width: 80)

            timeUnitLabel("hh")

            optionalMinutesRemainderField(minutes: minutes)
                .frame(width: 80)

            timeUnitLabel("mm")

            Spacer()
        }
    }

    private func comparisonMinutesRangeRow(
        title: String,
        glossaryTerm: String? = nil,
        mode: Binding<ComparisonFilterMode>,
        startMinutes: Binding<Int?>,
        endMinutes: Binding<Int?>
    ) -> some View {
        HStack(spacing: 12) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )
            .frame(width: 150, alignment: .leading)

            Picker(title, selection: mode) {
                ForEach(ComparisonFilterMode.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)

            optionalHoursField(minutes: startMinutes)
                .frame(width: 80)

            timeUnitLabel("hh")

            optionalMinutesRemainderField(minutes: startMinutes)
                .frame(width: 80)

            timeUnitLabel("mm")

            if mode.wrappedValue == .between {
                Text("and")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)

                optionalHoursField(minutes: endMinutes)
                    .frame(width: 80)

                timeUnitLabel("hh")

                optionalMinutesRemainderField(minutes: endMinutes)
                    .frame(width: 80)

                timeUnitLabel("mm")
            }

            Spacer()
        }
    }

    private func plainMinutesRow(
        title: String,
        glossaryTerm: String? = nil,
        minutes: Binding<Int?>
    ) -> some View {
        HStack(spacing: 12) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )
            .frame(width: 150, alignment: .leading)

            optionalHoursField(minutes: minutes)
                .frame(width: 80)

            timeUnitLabel("hh")

            optionalMinutesRemainderField(minutes: minutes)
                .frame(width: 80)

            timeUnitLabel("mm")

            Spacer()
        }
    }

    private func rangeMinutesRow(
        title: String,
        glossaryTerm: String? = nil,
        minMinutes: Binding<Int?>,
        maxMinutes: Binding<Int?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )

            HStack(spacing: 12) {
                Text("Min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalHoursField(minutes: minMinutes)
                    .frame(width: 80)

                timeUnitLabel("hh")

                optionalMinutesRemainderField(minutes: minMinutes)
                    .frame(width: 80)

                timeUnitLabel("mm")

                Text("Max")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)

                optionalHoursField(minutes: maxMinutes)
                    .frame(width: 80)

                timeUnitLabel("hh")

                optionalMinutesRemainderField(minutes: maxMinutes)
                    .frame(width: 80)

                timeUnitLabel("mm")

                Spacer()
            }
        }
    }

    private func recoveryMinutesRow(
        title: String,
        glossaryTerm: String? = nil,
        restMinutes: Binding<Int?>,
        triggerMinutes: Binding<Int?>,
        triggerLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )

            HStack(spacing: 12) {
                Text("Rest ≤")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalHoursField(minutes: restMinutes)
                    .frame(width: 80)

                timeUnitLabel("hh")

                optionalMinutesRemainderField(minutes: restMinutes)
                    .frame(width: 80)

                timeUnitLabel("mm")

                Text(triggerLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 14)

                optionalHoursField(minutes: triggerMinutes)
                    .frame(width: 80)

                timeUnitLabel("hh")

                optionalMinutesRemainderField(minutes: triggerMinutes)
                    .frame(width: 80)

                timeUnitLabel("mm")

                Spacer()
            }
        }
    }

    private func recoveryIntRow(
        title: String,
        glossaryTerm: String? = nil,
        restMinutes: Binding<Int?>,
        triggerValue: Binding<Int?>,
        triggerLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            filterLabel(
                title,
                glossaryTerm: glossaryTerm,
                font: .subheadline.weight(.semibold),
                secondary: false
            )

            HStack(spacing: 12) {
                Text("Rest ≤")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                optionalHoursField(minutes: restMinutes)
                    .frame(width: 80)

                timeUnitLabel("hh")

                optionalMinutesRemainderField(minutes: restMinutes)
                    .frame(width: 80)

                timeUnitLabel("mm")

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

    private func labeledTextField(
        title: String,
        glossaryTerm: String? = nil,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            filterLabel(title, glossaryTerm: glossaryTerm)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
        }
    }

    private func minimumPayField(
        title: String,
        glossaryTerm: String? = nil,
        value: Binding<Double?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            filterLabel(title, glossaryTerm: glossaryTerm)

            TextField(
                "Minimum",
                text: Binding(
                    get: {
                        guard let wrapped = value.wrappedValue else {
                            return ""
                        }

                        return String(format: "%.1f", wrapped)
                    },
                    set: { newValue in
                        value.wrappedValue = Double(newValue)
                    }
                )
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
        }
    }

    private func toggleChip(
        _ title: String,
        glossaryTerm: String? = nil,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 8) {
            Button {
                isOn.wrappedValue.toggle()
            } label: {
                HStack {
                    Image(
                        systemName: isOn.wrappedValue
                            ? "checkmark.circle.fill"
                            : "circle"
                    )

                    Text(title)
                        .fontWeight(.semibold)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    isOn.wrappedValue
                        ? .blue.opacity(0.16)
                        : Color(.systemBackground)
                )
                .foregroundStyle(isOn.wrappedValue ? .blue : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if let glossaryTerm {
                GlossaryInfoButton(term: glossaryTerm)
            }
        }
    }

    // MARK: - Inputs

    private var standardComparisonModes: [ComparisonFilterMode] {
        [
            .all,
            .greaterThanOrEqual,
            .lessThanOrEqual,
            .equalTo
        ]
    }

    private func optionalIntField(
        placeholder: String,
        value: Binding<Int?>
    ) -> some View {
        TextField(
            placeholder,
            text: Binding(
                get: {
                    guard let wrapped = value.wrappedValue else {
                        return ""
                    }

                    return "\(wrapped)"
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
                    guard !newValue.isEmpty else {
                        let remainder = (minutes.wrappedValue ?? 0) % 60
                        minutes.wrappedValue = remainder == 0 ? nil : remainder
                        return
                    }

                    guard let hours = Int(newValue), hours >= 0 else {
                        return
                    }

                    let remainder = (minutes.wrappedValue ?? 0) % 60
                    minutes.wrappedValue = hours * 60 + remainder
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
                    guard !newValue.isEmpty else {
                        let hours = (minutes.wrappedValue ?? 0) / 60
                        minutes.wrappedValue = hours == 0 ? nil : hours * 60
                        return
                    }

                    guard let remainder = Int(newValue),
                          (0...59).contains(remainder) else {
                        return
                    }

                    let hours = (minutes.wrappedValue ?? 0) / 60
                    minutes.wrappedValue = hours * 60 + remainder
                }
            )
        )
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
    }

    private func timeUnitLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Selection Chips

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

    private func dayChip(
        _ days: Int,
        title: String
    ) -> some View {
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

    // MARK: - Dates

    private func dateString(
        from components: DateComponents
    ) -> String? {
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }

    private func dateComponentsFromFilterStrings() -> Set<DateComponents> {
        Set(
            viewModel.filters.touchDateStrings.compactMap { string in
                let parts = string
                    .split(separator: "-")
                    .compactMap { Int($0) }

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
