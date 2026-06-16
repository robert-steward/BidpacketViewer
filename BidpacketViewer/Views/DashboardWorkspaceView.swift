
import SwiftUI

struct DashboardWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                compactSummarySection
                selectedPlanSection

                HStack(alignment: .top, spacing: 18) {
                    dashboardGroup(title: "Rotation Mix") {
                        VStack(spacing: 16) {
                            ForEach(viewModel.rotationsByLength, id: \.label) { item in
                                largeBarRow(
                                    label: item.label,
                                    primaryValue: "\(item.instances)",
                                    secondaryValue: "\(item.rotations) rot.",
                                    count: item.instances,
                                    total: max(viewModel.instanceCount, 1)
                                )
                            }
                        }
                    }

                    dashboardGroup(title: "Operational") {
                        VStack(spacing: 16) {
                            iconStatRow("🌙", "Red-eyes", "\(viewModel.totalRedeyes)")
                            iconStatRow("🏨", "Day Layovers", "\(viewModel.totalDayLayovers)")
                            iconStatRow("🚕", "Cross-town", "\(viewModel.totalCrossTownLayovers)")
                            iconStatRow("🚌", "Front DH", "\(viewModel.frontDeadheadCount)")
                            iconStatRow("🚌", "Back DH", "\(viewModel.backDeadheadCount)")
                            iconStatRow("🦵", "Max Legs", "\(viewModel.maxLegsInAnyDutyPeriod)")
                            iconStatRow("⏱️", "Longest FDP", viewModel.formatMinutesAsHM(viewModel.longestFDPMinutes))
                        }
                    }
                }

                HStack(alignment: .top, spacing: 18) {
                    dashboardGroup(title: "Commutability") {
                        VStack(spacing: 16) {
                            coloredBarRow("🟢", "Fully", count: viewModel.fullyCommutableCount)
                            coloredBarRow("🟡", "Front-only", count: viewModel.frontOnlyCommutableCount)
                            coloredBarRow("🔵", "Back-only", count: viewModel.backOnlyCommutableCount)
                        }
                    }

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
            }
            .padding(28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(viewModel.primaryBase) \(viewModel.bidpacket?.aircraft ?? "Unknown Aircraft")")
                .font(.system(size: 48, weight: .bold))

            if let month = viewModel.bidpacket?.bidpacketMonth,
               let year = viewModel.bidpacket?.bidpacketYear {
                Text("\(monthName(month)) \(year)")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }

            Text("\(viewModel.rotationCount) rotations • \(viewModel.instanceCount) instances")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var compactSummarySection: some View {
        HStack(spacing: 14) {
            compactMetric("Credit", viewModel.formatMinutesAsCredit(viewModel.totalCreditMinutes))
            compactMetric("Avg Credit", viewModel.formatMinutesAsCredit(viewModel.averageCreditPerInstanceMinutes))
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

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: month, day: 1))
        return date.map { formatter.string(from: $0) } ?? "\(month)"
    }
}
