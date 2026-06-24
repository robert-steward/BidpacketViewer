import SwiftUI

struct DashboardWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                topSummarySection
                selectedPlanSection

                HStack(alignment: .top, spacing: 18) {
                    rotationMixSection
                    operationalSection
                }

                HStack(alignment: .top, spacing: 18) {
                    commutabilitySection
                    restSection
                }

                HStack(alignment: .top, spacing: 18) {
                    circadianSection
                    topOvernightsSection
                }
                
                if viewModel.primaryBase == "NYC" || viewModel.primaryBase == "LAX" {
                    HStack(alignment: .top, spacing: 18) {
                        coTerminalSection
                    }
                }
                
                HStack(alignment: .top, spacing: 18) {
                    creditByLengthSection
                    dutyMetricsSection
                }
                
                HStack(alignment: .top, spacing: 18) {
                    rotationMixSection
                    rotationMixScoreSection
                }

                HStack(alignment: .top, spacing: 18) {
                    lastDutyOneLegSection
                }
            }
            .padding(28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
    }
    
    private var rotationMixScoreSection: some View {
        dashboardGroup(title: "Rotation Mix") {
            VStack(spacing: 16) {
                HStack {
                    Text("Mix Score")
                        .font(.headline)

                    Spacer()

                    Text(String(format: "%.1f", viewModel.rotationMixScore))
                        .font(.system(size: 32, weight: .bold))
                }

                Divider()

                ForEach(viewModel.rotationMixRows, id: \.label) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.label)
                                .font(.headline)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Act: \(String(format: "%.1f", item.actual))%")
                                    .font(.headline)

                                Text("Tgt: \(String(format: "%.1f", item.target))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ProgressView(value: item.actual, total: 100)
                            .scaleEffect(x: 1, y: 1.6, anchor: .center)
                    }
                }

                Text("Weight: \(String(format: "%.2f", viewModel.rotationMixWeight))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var coTerminalSection: some View {
        dashboardGroup(title: "Co-terminal Departures") {
            VStack(spacing: 16) {

                ForEach(viewModel.coTerminalDepartures, id: \.station) { item in

                    largeBarRow(
                        label: item.station,
                        primaryValue: "\(item.count)",
                        secondaryValue: String(
                            format: "%.1f%%",
                            viewModel.coTerminalTotal > 0
                            ? Double(item.count) * 100.0 / Double(viewModel.coTerminalTotal)
                            : 0
                        ),
                        count: item.count,
                        total: max(viewModel.coTerminalTotal, 1)
                    )
                }
            }
        }
    }
    
    private var creditByLengthSection: some View {
        dashboardGroup(title: "Credit by # Days") {
            VStack(spacing: 16) {
                ForEach(viewModel.creditByLength, id: \.label) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.label)
                                .font(.headline)

                            Spacer()

                            Text(viewModel.formatMinutesAsCredit(item.creditMinutes))
                                .font(.headline)

                            Text("credit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("BL \(viewModel.formatMinutesAsCredit(item.blockMinutes))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(item.instances) instances")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Avg \(viewModel.formatMinutesAsCredit(item.avgCreditPerInstance))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(
                            value: Double(item.creditMinutes),
                            total: Double(max(viewModel.totalCreditMinutes, 1))
                        )
                        .scaleEffect(x: 1, y: 1.7, anchor: .center)
                    }
                }
            }
        }
    }

    private var dutyMetricsSection: some View {
        dashboardGroup(title: "Duty Metrics") {
            VStack(spacing: 16) {
                iconStatRow("🧭", "Avg Duty Periods", String(format: "%.1f", viewModel.averageDutyPeriods))
                iconStatRow("🦵", "Avg Legs / Day", String(format: "%.1f", viewModel.averageLegsPerDay))
                iconStatRow("⚙️", "Avg Duty Efficiency", String(format: "%.2f", viewModel.averageDutyEfficiency))
                iconStatRow("⏳", "Avg TAFB", String(format: "%.2f", viewModel.averageTAFB))
                iconStatRow("⏱️", "Avg Credit / Instance", viewModel.formatMinutesAsCredit(viewModel.averageCreditPerInstanceMinutes))
            }
        }
    }

    private var lastDutyOneLegSection: some View {
        dashboardGroup(title: "Last Duty Period = One Leg") {
            VStack(spacing: 16) {
                ForEach(viewModel.lastDutyOneLegRows, id: \.label) { item in
                    coloredBarRow(
                        item.label == "Overall" ? "🏁" : "✈️",
                        item.label,
                        count: item.count
                    )
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(viewModel.primaryBase) \(viewModel.aircraft)")
                .font(.system(size: 48, weight: .bold))

            Text(viewModel.bidpacketName ?? "Bidpacket")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("\(viewModel.rotationCount) rotations • \(viewModel.instanceCount) instances")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var topSummarySection: some View {
        HStack(spacing: 14) {
            compactMetric("Rotations", "\(viewModel.rotationCount)")
            compactMetric("Instances", "\(viewModel.instanceCount)")
            compactMetric("Avg Score", formatScore(viewModel.summary?.averageScore))
            compactMetric("Selected", "\(viewModel.selectedCount)")
            compactMetric("Selected Credit", viewModel.formatMinutesAsCredit(viewModel.selectedCreditMinutes))
        }
    }

    private var selectedPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Current Plan")
                    .font(.title2.bold())

                Spacer()

                Text("⭐")
                    .font(.title2)
            }

            HStack(spacing: 28) {
                planMetric("Rotations", "\(viewModel.selectedCount)")
                planMetric("Instances", "\(viewModel.selectedInstanceCount)")
                planMetric("Credit", viewModel.formatMinutesAsCredit(viewModel.selectedCreditMinutes))
                planMetric("Avg", viewModel.formatMinutesAsCredit(viewModel.selectedAverageCreditPerInstanceMinutes))
            }
        }
        .padding(22)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var rotationMixSection: some View {
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

    private var operationalSection: some View {
        dashboardGroup(title: "Operational") {
            VStack(spacing: 16) {
                iconStatRow("🌙", "Red-eyes", "\(viewModel.totalRedeyes)")
                iconStatRow("🏨", "Day Layovers", "\(viewModel.totalDayLayovers)")
                iconStatRow("🚌", "DH-only Day Layovers", "\(viewModel.summary?.dayLayoversDHOnlyTotal ?? 0)")
                iconStatRow("🚕", "Cross-town", "\(viewModel.totalCrossTownLayovers)")
                iconStatRow("🚌", "Front DH", "\(viewModel.frontDeadheadCount)")
                iconStatRow("🚌", "Back DH", "\(viewModel.backDeadheadCount)")
                iconStatRow("🦵", "Max Legs", "\(viewModel.maxLegsInAnyDutyPeriod)")
                iconStatRow("⏱️", "Longest FDP", viewModel.formatMinutesAsHM(viewModel.longestFDPMinutes))
            }
        }
    }

    private var commutabilitySection: some View {
        dashboardGroup(title: "Commutability") {
            VStack(spacing: 16) {
                coloredBarRow("🟢", "Fully", count: viewModel.fullyCommutableCount)
                coloredBarRow("🟡", "Front-only", count: viewModel.frontOnlyCommutableCount)
                coloredBarRow("🔵", "Back-only", count: viewModel.backOnlyCommutableCount)
                coloredBarRow("⚪️", "Not Commutable", count: viewModel.notCommutableCount)

                Divider()

                iconStatRow("🛫", "Front no earlier than", viewModel.frontNoEarlierThan)
                iconStatRow("🛬", "Back no later than", viewModel.backNoLaterThan)
            }
        }
    }

    private var restSection: some View {
        dashboardGroup(title: "Average Rest") {
            VStack(spacing: 16) {
                restCard(
                    title: "No Red-eye",
                    value: viewModel.avgRestNoRedeyeHM,
                    subtitle: "\(viewModel.avgRestNoRedeyeOvernightsCount) overnights"
                )

                restCard(
                    title: "With Red-eye",
                    value: viewModel.avgRestWithRedeyeHM,
                    subtitle: "\(viewModel.avgRestWithRedeyeOvernightsCount) overnights"
                )
            }
        }
    }

    private var circadianSection: some View {
        dashboardGroup(title: "Circadian Swaps") {
            VStack(spacing: 16) {
                iconStatRow("🔁", "Total", "\(viewModel.circadianSwapTotal)")
                iconStatRow("🌙", "PM to AM", "\(viewModel.circadianPmToAmCount)")
                iconStatRow("🟥", "Red-eye to AM", "\(viewModel.circadianRedeyeToAmCount)")
                iconStatRow("🌅", "AM to PM", "\(viewModel.circadianAmToPmCount)")

                Divider()

                iconStatRow("✅", "Mitigated Total", "\(viewModel.mitigatedCircadianSwapTotal)")
                iconStatRow("✅", "Mitigated PM to AM", "\(viewModel.mitigatedPmToAmCount)")
                iconStatRow("✅", "Mitigated Red-eye to AM", "\(viewModel.mitigatedRedeyeToAmCount)")
                iconStatRow("✅", "Mitigated AM to PM", "\(viewModel.mitigatedAmToPmCount)")
            }
        }
    }

    private var topOvernightsSection: some View {
        dashboardGroup(title: "Top Overnights") {
            VStack(spacing: 16) {
                ForEach(viewModel.topOvernights.prefix(8), id: \.station) { item in
                    largeBarRow(
                        label: item.station,
                        primaryValue: "\(item.count)",
                        secondaryValue: percentText(Double(item.count) / Double(max(viewModel.instanceCount, 1))),
                        count: item.count,
                        total: max(viewModel.instanceCount, 1)
                    )
                }
            }
        }
    }

    private var summaryDayRows: [(label: String, count: Int, average: Double?)] {
        guard let avgByDays = viewModel.summary?.avgByDays else {
            return viewModel.rotationsByLength.map {
                (label: $0.label, count: $0.instances, average: nil)
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

    private func compactMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func planMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dashboardGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.title2.bold())

            content()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func restCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(value)
                .font(.system(size: 34, weight: .bold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func largeBarRow(
        label: String,
        primaryValue: String,
        secondaryValue: String,
        count: Int,
        total: Int
    ) -> some View {
        let percent = Double(count) / Double(max(total, 1))

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
                .scaleEffect(x: 1, y: 1.7, anchor: .center)

            Text("\(percentText(percent)) of instances")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func coloredBarRow(_ icon: String, _ label: String, count: Int) -> some View {
        let total = max(viewModel.instanceCount, 1)
        let percent = Double(count) / Double(total)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)

                Text(label)
                    .font(.headline)

                Spacer()

                Text("\(count)")
                    .font(.headline)

                Text(percentText(percent))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: percent)
                .scaleEffect(x: 1, y: 1.7, anchor: .center)
        }
    }

    private func iconStatRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .frame(width: 28)

            Text(label)
                .font(.headline)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func percentText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func formatScore(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.3f", value)
    }
}
