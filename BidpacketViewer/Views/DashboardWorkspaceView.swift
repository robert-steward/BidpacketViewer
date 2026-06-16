//
//  DashboardWorkspaceView.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/15/26.
//

import SwiftUI

struct DashboardWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(viewModel.primaryBase) \(viewModel.bidpacket?.aircraft ?? "Unknown Aircraft")")
                    .font(.largeTitle.bold())

                Text("Dashboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    dashboardCard(title: "Rotations", value: "\(viewModel.rotationCount)")
                    dashboardCard(title: "Instances", value: "\(viewModel.instanceCount)")
                    dashboardCard(title: "Selected", value: "\(viewModel.selectedCount)")
                }

                dashboardGroup(title: "By Length") {
                    VStack(spacing: 10) {
                        lengthRow("1 Day", count: countByDays(1))
                        lengthRow("2 Day", count: countByDays(2))
                        lengthRow("3 Day", count: countByDays(3))
                        lengthRow("4 Day", count: countByDays(4))
                        lengthRow("5+ Day", count: countFivePlus())
                    }
                }

                dashboardGroup(title: "Top Overnights") {
                    VStack(spacing: 10) {
                        ForEach(topOvernights, id: \.station) { item in
                            lengthRow(item.station, count: item.count)
                        }
                    }
                }
            }
            .padding(28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
    }

    private func dashboardCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 34, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func dashboardGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func lengthRow(_ label: String, count: Int) -> some View {
        HStack {
            Text(label)
                .font(.headline)

            Spacer()

            Text("\(count)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func countByDays(_ days: Int) -> Int {
        viewModel.rotations.filter { $0.numDays == days }.count
    }

    private func countFivePlus() -> Int {
        viewModel.rotations.filter { ($0.numDays ?? 0) >= 5 }.count
    }

    private var topOvernights: [(station: String, count: Int)] {
        var counts: [String: Int] = [:]

        for rotation in viewModel.rotations {
            guard let overnights = rotation.overnights else { continue }

            for part in overnights.split(separator: ",") {
                let station = part
                    .split(separator: ":")
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let station, !station.isEmpty {
                    counts[station, default: 0] += 1
                }
            }
        }

        return counts
            .map { (station: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }
}
