import SwiftUI

struct DashboardWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    @AppStorage("dashboardExcludeShortCommutability")
    private var excludeShortCommutability = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                topSummarySection

                if viewModel.selectedCount > 0 {
                    selectedPlanSection
                }

                HStack(alignment: .top, spacing: 18) {
                    averageByDaysSection
                    operationalSection
                }

                HStack(alignment: .top, spacing: 18) {
                    commutabilitySection
                    restSection
                }

                if viewModel.primaryBase == "NYC" ||
                    viewModel.primaryBase == "LAX" {
                    coTerminalSection
                }

                HStack(alignment: .top, spacing: 18) {
                    rotationMixSection
                    lastDutyOneLegSection
                }

                HStack(alignment: .top, spacing: 18) {
                    creditByLengthSection
                    dutyMetricsSection
                }

                HStack(alignment: .top, spacing: 18) {
                    circadianSection
                    topOvernightsSection
                }

                regionMixSection
            }
            .padding(28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
    }

    // MARK: - Header and Summary

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(viewModel.primaryBase) \(viewModel.aircraft)")
                .font(.system(size: 48, weight: .bold))

            Text(viewModel.bidpacketName ?? "Bidpacket")
                .font(.title)
                .foregroundStyle(.secondary)

            Text(
                "\(viewModel.rotationCount) rotations • " +
                "\(viewModel.instanceCount) instances"
            )
            .font(.headline)
            .foregroundStyle(.secondary)
        }
    }

    private var topSummarySection: some View {
        HStack(spacing: 14) {
            compactMetric(
                "Rotations",
                "\(viewModel.rotationCount)",
                glossaryTerm: "Rotation"
            )

            compactMetric(
                "Instances",
                "\(viewModel.instanceCount)",
                glossaryTerm: "Instance"
            )

            compactMetric(
                "Avg Score",
                formatScore(viewModel.summary?.averageScore)
            )

            compactMetric(
                "Selected",
                "\(viewModel.selectedCount)",
                glossaryTerm: "Selected Rotation"
            )

            compactMetric(
                "Selected Credit",
                viewModel.formatMinutesAsCredit(
                    viewModel.selectedCreditMinutes
                ),
                glossaryTerm: "Total Credit"
            )
        }
    }

    private var selectedPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            dashboardTitle(
                "Selected Rotations",
                glossaryTerm: "Selected Rotation"
            )

            HStack(spacing: 28) {
                planMetric(
                    "Rotations",
                    "\(viewModel.selectedCount)"
                )

                planMetric(
                    "Instances",
                    "\(viewModel.selectedInstanceCount)"
                )

                planMetric(
                    "Credit",
                    viewModel.formatMinutesAsCredit(
                        viewModel.selectedCreditMinutes
                    )
                )

                planMetric(
                    "Avg",
                    viewModel.formatMinutesAsCredit(
                        viewModel.selectedAverageCreditPerInstanceMinutes
                    )
                )
            }
        }
        .padding(22)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Average by Length

    private var averageByDaysSection: some View {
        dashboardGroup(title: "Avg by # Days") {
            VStack(spacing: 16) {
                ForEach(summaryDayRows, id: \.label) { item in
                    largeBarRow(
                        label: item.label,
                        primaryValue: "\(item.count)",
                        secondaryValue: "Avg \(formatScore(item.average))",
                        count: item.count,
                        total: max(viewModel.instanceCount, 1)
                    )
                }
            }
        }
    }

    private var summaryDayRows:
        [(label: String, count: Int, average: Double?)] {
        guard let avgByDays = viewModel.summary?.avgByDays else {
            return viewModel.rotationsByLength.map {
                (
                    label: $0.label,
                    count: $0.instances,
                    average: nil
                )
            }
        }

        return avgByDays.keys
            .compactMap { Int($0) }
            .sorted()
            .map { day in
                let key = String(day)
                let value = avgByDays[key]

                return (
                    label: day == 1 ? "1 Day" : "\(day) Day",
                    count: value?.count ?? 0,
                    average: value?.averageScore
                )
            }
    }

    // MARK: - Operational

    private var operationalSection: some View {
        dashboardGroup(title: "Operational") {
            VStack(spacing: 16) {
                iconStatRow(
                    "🌙",
                    "Red-eyes",
                    "\(viewModel.totalRedeyes)",
                    glossaryTerm: "Red-eye"
                )

                iconStatRow(
                    "🏨",
                    "Day Layovers",
                    "\(viewModel.totalDayLayovers)",
                    glossaryTerm: "Day Layover"
                )

                iconStatRow(
                    "🚌",
                    "DH-only Day Layovers",
                    "\(viewModel.summary?.dayLayoversDHOnlyTotal ?? 0)",
                    glossaryTerm: "Deadhead-only Day Layover"
                )

                iconStatRow(
                    "🚕",
                    "Cross-town",
                    "\(viewModel.totalCrossTownLayovers)",
                    glossaryTerm: "Cross-town Layover"
                )

                iconStatRow(
                    "🚌",
                    "Front DH",
                    "\(viewModel.frontDeadheadCount)",
                    glossaryTerm: "Front Deadhead"
                )

                iconStatRow(
                    "🚌",
                    "Back DH",
                    "\(viewModel.backDeadheadCount)",
                    glossaryTerm: "Back Deadhead"
                )

                iconStatRow(
                    "🦵",
                    "Max Legs",
                    "\(viewModel.maxLegsInAnyDutyPeriod)"
                )

                iconStatRow(
                    "⏱️",
                    "Longest FDP",
                    viewModel.formatMinutesAsHM(
                        viewModel.longestFDPMinutes
                    ),
                    glossaryTerm: "Longest FDP"
                )
            }
        }
    }

    // MARK: - Commutability

    private var commutabilitySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                dashboardTitle(
                    "Commutability",
                    glossaryTerm: "Fully Commutable"
                )

                Spacer()

                Toggle(
                    "Exclude 1 & 2 day",
                    isOn: $excludeShortCommutability
                )
                .font(.caption)
                .toggleStyle(.switch)
            }

            VStack(spacing: 16) {
                coloredBarRow(
                    "🟢",
                    "Fully",
                    count: dashboardFullyCommutableCount,
                    total: dashboardCommutabilityTotal,
                    glossaryTerm: "Fully Commutable"
                )

                coloredBarRow(
                    "🟡",
                    "Front-only",
                    count: dashboardFrontOnlyCommutableCount,
                    total: dashboardCommutabilityTotal,
                    glossaryTerm: "Front-only Commutable"
                )

                coloredBarRow(
                    "🔵",
                    "Back-only",
                    count: dashboardBackOnlyCommutableCount,
                    total: dashboardCommutabilityTotal,
                    glossaryTerm: "Back-only Commutable"
                )

                coloredBarRow(
                    "🔴",
                    "Not Commutable",
                    count: dashboardNotCommutableCount,
                    total: dashboardCommutabilityTotal,
                    glossaryTerm: "Not Commutable"
                )

                Divider()

                iconStatRow(
                    "🛫",
                    "Front no earlier than",
                    viewModel.frontNoEarlierThan,
                    glossaryTerm: "Commute In"
                )

                iconStatRow(
                    "🛬",
                    "Back no later than",
                    viewModel.backNoLaterThan,
                    glossaryTerm: "Commute Home"
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var dashboardCommutabilityRotations: [Rotation] {
        viewModel.rotations.filter { rotation in
            !excludeShortCommutability ||
            (rotation.numDays ?? 0) >= 3
        }
    }

    private var dashboardCommutabilityTotal: Int {
        dashboardCommutabilityRotations.reduce(0) {
            $0 + viewModel.occurrenceWeight($1)
        }
    }

    private var dashboardFullyCommutableCount: Int {
        dashboardCommutabilityRotations.reduce(0) {
            $0 + (
                $1.fullyCommutable == true
                    ? viewModel.occurrenceWeight($1)
                    : 0
            )
        }
    }

    private var dashboardFrontOnlyCommutableCount: Int {
        dashboardCommutabilityRotations.reduce(0) {
            total,
            rotation in

            let isFrontOnly =
                rotation.frontCommutable == true &&
                rotation.backCommutable != true &&
                rotation.fullyCommutable != true

            return total + (
                isFrontOnly
                    ? viewModel.occurrenceWeight(rotation)
                    : 0
            )
        }
    }

    private var dashboardBackOnlyCommutableCount: Int {
        dashboardCommutabilityRotations.reduce(0) {
            total,
            rotation in

            let isBackOnly =
                rotation.backCommutable == true &&
                rotation.frontCommutable != true &&
                rotation.fullyCommutable != true

            return total + (
                isBackOnly
                    ? viewModel.occurrenceWeight(rotation)
                    : 0
            )
        }
    }

    private var dashboardNotCommutableCount: Int {
        dashboardCommutabilityRotations.reduce(0) {
            total,
            rotation in

            let isCommutable =
                rotation.frontCommutable == true ||
                rotation.backCommutable == true ||
                rotation.fullyCommutable == true

            return total + (
                !isCommutable
                    ? viewModel.occurrenceWeight(rotation)
                    : 0
            )
        }
    }

    // MARK: - Rest

    private var restSection: some View {
        dashboardGroup(title: "Average Rest") {
            VStack(spacing: 16) {
                restCard(
                    title: "No Red-eye/Circ-swap",
                    value: viewModel.avgRestNoRedeyeHM,
                    subtitle:
                        "\(viewModel.avgRestNoRedeyeOvernightsCount) overnights",
                    glossaryTerm:
                        "Average Rest: No Red-eye/Circ-Swap"
                )

                restCard(
                    title: "With Red-eye and/or Circ-swap",
                    value: viewModel.avgRestWithRedeyeHM,
                    subtitle:
                        "\(viewModel.avgRestWithRedeyeOvernightsCount) overnights",
                    glossaryTerm:
                        "Average Rest: With Red-eye or Circ-Swap"
                )
            }
        }
    }

    // MARK: - Co-terminal

    private var coTerminalSection: some View {
        dashboardGroup(title: "Co-terminal Departures") {
            VStack(spacing: 16) {
                ForEach(
                    viewModel.coTerminalDepartures,
                    id: \.station
                ) { item in
                    largeBarRow(
                        label: item.station,
                        primaryValue: "\(item.count)",
                        secondaryValue: String(
                            format: "%.1f%%",
                            viewModel.coTerminalTotal > 0
                                ? Double(item.count) * 100.0 /
                                  Double(viewModel.coTerminalTotal)
                                : 0
                        ),
                        count: item.count,
                        total: max(
                            viewModel.coTerminalTotal,
                            1
                        )
                    )
                }
            }
        }
    }

    // MARK: - Rotation Mix

    private var rotationMixSection: some View {
        dashboardGroup(title: "Rotation Mix") {
            VStack(spacing: 16) {
                HStack {
                    Text("Mix Score")
                        .font(.headline)

                    Spacer()

                    Text(
                        String(
                            format: "%.1f",
                            viewModel.rotationMixScore
                        )
                    )
                    .font(.system(size: 32, weight: .bold))
                }

                Divider()

                ForEach(
                    viewModel.rotationMixRows,
                    id: \.label
                ) { item in
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        HStack {
                            Text(item.label)
                                .font(.headline)

                            Spacer()

                            VStack(
                                alignment: .trailing,
                                spacing: 2
                            ) {
                                Text(
                                    "Act: " +
                                    String(
                                        format: "%.1f",
                                        item.actual
                                    ) +
                                    "%"
                                )
                                .font(.headline)

                                Text(
                                    "Tgt: " +
                                    String(
                                        format: "%.1f",
                                        item.target
                                    ) +
                                    "%"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        ProgressView(
                            value: item.actual,
                            total: 100
                        )
                        .scaleEffect(
                            x: 1,
                            y: 1.6,
                            anchor: .center
                        )
                    }
                }

                Text(
                    "Weight: " +
                    String(
                        format: "%.2f",
                        viewModel.rotationMixWeight
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Last Duty One Leg

    private var lastDutyOneLegSection: some View {
        dashboardGroup(title: "Last Duty Period = One Leg") {
            VStack(spacing: 16) {
                ForEach(
                    viewModel.lastDutyOneLegRows,
                    id: \.label
                ) { item in
                    coloredBarRow(
                        item.label == "Overall"
                            ? "🏁"
                            : "✈️",
                        item.label,
                        count: item.count
                    )
                }
            }
        }
    }

    // MARK: - Credit and Duty Metrics

    private var creditByLengthSection: some View {
        dashboardGroup(
            title: "Credit by # Days",
            glossaryTerm: "Total Credit"
        ) {
            VStack(spacing: 16) {
                ForEach(
                    viewModel.creditByLength,
                    id: \.label
                ) { item in
                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {
                        HStack {
                            Text(item.label)
                                .font(.headline)

                            Spacer()

                            Text(
                                viewModel.formatMinutesAsCredit(
                                    item.creditMinutes
                                )
                            )
                            .font(.headline)

                            Text("credit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text(
                                "BL " +
                                viewModel.formatMinutesAsCredit(
                                    item.blockMinutes
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Text(
                                    "Syn " +
                                    syntheticCreditText(
                                        block: item.blockMinutes,
                                        credit: item.creditMinutes
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                GlossaryInfoButton(term: "Synthetic Credit")
                            }
                            
                            Spacer()

                            Text("\(item.instances) instances")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                "Avg " +
                                viewModel.formatMinutesAsCredit(
                                    item.avgCreditPerInstance
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(
                            value: Double(item.creditMinutes),
                            total: Double(
                                max(
                                    viewModel.totalCreditMinutes,
                                    1
                                )
                            )
                        )
                        .scaleEffect(
                            x: 1,
                            y: 1.7,
                            anchor: .center
                        )
                    }
                }
            }
        }
    }

    private var dutyMetricsSection: some View {
        dashboardGroup(title: "Duty Metrics") {
            VStack(spacing: 16) {
                iconStatRow(
                    "🧭",
                    "Avg Duty Periods",
                    String(
                        format: "%.1f",
                        viewModel.averageDutyPeriods
                    ),
                    glossaryTerm: "Duty Period"
                )

                iconStatRow(
                    "🦵",
                    "Avg Legs / Day",
                    String(
                        format: "%.1f",
                        viewModel.averageLegsPerDay
                    )
                )

                iconStatRow(
                    "⚙️",
                    "Avg Duty Efficiency",
                    String(
                        format: "%.2f",
                        viewModel.averageDutyEfficiency
                    ),
                    glossaryTerm: "Duty Efficiency"
                )

                iconStatRow(
                    "⏳",
                    "Avg TAFB",
                    String(
                        format: "%.2f",
                        viewModel.averageTAFB
                    ),
                    glossaryTerm: "TAFB"
                )

                iconStatRow(
                    "⏱️",
                    "Avg Credit / Instance",
                    viewModel.formatMinutesAsCredit(
                        viewModel.averageCreditPerInstanceMinutes
                    ),
                    glossaryTerm: "Credit Per Day"
                )
            }
        }
    }

    // MARK: - Circadian

    
    private func syntheticCreditText(
        block: Int,
        credit: Int
    ) -> String {
        guard credit > 0 else { return "—" }

        let sc = (1.0 - Double(block) / Double(credit)) * 100.0
        return String(format: "%.1f%%", sc)
    }
    
    private var circadianSection: some View {
        dashboardGroup(
            title: "Circadian Swaps",
            glossaryTerm: "Circadian Swap"
        ) {
            VStack(spacing: 16) {
                iconStatRow(
                    "🔁",
                    "Total",
                    "\(viewModel.circadianSwapTotal)",
                    glossaryTerm: "Circadian Swap"
                )

                iconStatRow(
                    "🌙",
                    "PM to AM",
                    "\(viewModel.circadianPmToAmCount)",
                    glossaryTerm: "PM-to-AM Swap"
                )

                iconStatRow(
                    "🟥",
                    "Red-eye to AM",
                    "\(viewModel.circadianRedeyeToAmCount)",
                    glossaryTerm: "Red-eye-to-AM Swap"
                )

                iconStatRow(
                    "🌅",
                    "AM to PM",
                    "\(viewModel.circadianAmToPmCount)",
                    glossaryTerm: "AM-to-PM Swap"
                )

                Divider()

                iconStatRow(
                    "✅",
                    "Mitigated Total",
                    "\(viewModel.mitigatedCircadianSwapTotal)",
                    glossaryTerm: "Mitigated Circadian Swap"
                )

                iconStatRow(
                    "✅",
                    "Mitigated PM to AM",
                    "\(viewModel.mitigatedPmToAmCount)",
                    glossaryTerm: "Mitigated Circadian Swap"
                )

                iconStatRow(
                    "✅",
                    "Mitigated Red-eye to AM",
                    "\(viewModel.mitigatedRedeyeToAmCount)",
                    glossaryTerm: "Mitigated Circadian Swap"
                )

                iconStatRow(
                    "✅",
                    "Mitigated AM to PM",
                    "\(viewModel.mitigatedAmToPmCount)",
                    glossaryTerm: "Mitigated Circadian Swap"
                )
            }
        }
    }

    // MARK: - Overnights

    private var topOvernightsSection: some View {
        dashboardGroup(
            title: "Top Overnights",
            glossaryTerm: "Overnight"
        ) {
            VStack(spacing: 16) {
                ForEach(
                    viewModel.topOvernights.prefix(8),
                    id: \.station
                ) { item in
                    largeBarRow(
                        label: item.station,
                        primaryValue: "\(item.count)",
                        secondaryValue: percentText(
                            Double(item.count) /
                            Double(
                                max(
                                    viewModel.instanceCount,
                                    1
                                )
                            )
                        ),
                        count: item.count,
                        total: max(
                            viewModel.instanceCount,
                            1
                        )
                    )
                }
            }
        }
    }

    // MARK: - Region Mix

    private var regionMixSection: some View {
        dashboardGroup(
            title: "Region Mix",
            glossaryTerm: "Region"
        ) {
            VStack(spacing: 16) {
                ForEach(
                    regionMixRows,
                    id: \.region
                ) { item in
                    largeBarRow(
                        label: item.region,
                        primaryValue: "\(item.count)",
                        secondaryValue:
                            percentText(item.percent),
                        count: item.count,
                        total: max(
                            viewModel.instanceCount,
                            1
                        )
                    )
                }
            }
        }
    }

    private var regionMixRows:
        [(region: String, count: Int, percent: Double)] {
        var counts: [String: Int] = [:]
        let total = max(viewModel.instanceCount, 1)

        for rotation in viewModel.rotations {
            let weight =
                viewModel.occurrenceWeight(rotation)

            guard let touches = rotation.touches,
                  !touches.isEmpty else {
                continue
            }

            let regions =
                AirportLookup.shared.regions(
                    for: touches.keys
                )

            if regions.isEmpty {
                continue
            }

            if regions == ["Domestic"] {
                counts["Domestic", default: 0] += weight
            } else {
                for region in regions
                where region != "Domestic" {
                    counts[region, default: 0] += weight
                }
            }
        }

        return counts
            .map { region, count in
                (
                    region: region,
                    count: count,
                    percent:
                        Double(count) / Double(total)
                )
            }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Reusable Components

    private func dashboardTitle(
        _ title: String,
        glossaryTerm: String? = nil
    ) -> some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.title2.bold())

            if let glossaryTerm {
                GlossaryInfoButton(term: glossaryTerm)
            }
        }
    }

    private func compactMetric(
        _ title: String,
        _ value: String,
        glossaryTerm: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let glossaryTerm {
                    GlossaryInfoButton(term: glossaryTerm)
                }
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 86,
            alignment: .leading
        )
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func planMetric(
        _ title: String,
        _ value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func dashboardGroup<Content: View>(
        title: String,
        glossaryTerm: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            dashboardTitle(
                title,
                glossaryTerm: glossaryTerm
            )

            content()
        }
        .padding(22)
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func restCard(
        title: String,
        value: String,
        subtitle: String,
        glossaryTerm: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.headline)

                if let glossaryTerm {
                    GlossaryInfoButton(term: glossaryTerm)
                }
            }

            Text(value)
                .font(.system(size: 34, weight: .bold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(18)
        .background(
            Color(.secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func largeBarRow(
        label: String,
        primaryValue: String,
        secondaryValue: String,
        count: Int,
        total: Int
    ) -> some View {
        let percent =
            Double(count) / Double(max(total, 1))

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)

                Spacer()

                Text(primaryValue)
                    .font(.headline)

                Text(secondaryValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: percent)
                .scaleEffect(
                    x: 1,
                    y: 1.7,
                    anchor: .center
                )

            Text("\(percentText(percent)) of instances")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func coloredBarRow(
        _ icon: String,
        _ label: String,
        count: Int,
        total: Int? = nil,
        glossaryTerm: String? = nil
    ) -> some View {
        let denominator =
            max(total ?? viewModel.instanceCount, 1)

        let percent =
            Double(count) / Double(denominator)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(icon)

                Text(label)
                    .font(.headline)

                if let glossaryTerm {
                    GlossaryInfoButton(term: glossaryTerm)
                }

                Spacer()

                Text("\(count)")
                    .font(.headline)

                Text(percentText(percent))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: percent)
                .scaleEffect(
                    x: 1,
                    y: 1.7,
                    anchor: .center
                )
        }
    }

    private func iconStatRow(
        _ icon: String,
        _ label: String,
        _ value: String,
        glossaryTerm: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .frame(width: 28)

            Text(label)
                .font(.headline)

            if let glossaryTerm {
                GlossaryInfoButton(term: glossaryTerm)
            }

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func percentText(
        _ value: Double
    ) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func formatScore(
        _ value: Double?
    ) -> String {
        guard let value else {
            return "—"
        }

        return String(format: "%.3f", value)
    }
}

#Preview {
    DashboardWorkspaceView(
        viewModel: BidpacketViewModel()
    )
}

