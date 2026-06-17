import SwiftUI

struct DashboardView: View {
    @State private var viewModel = BidpacketViewModel()
    @State private var selectedWorkspace: AppWorkspace = .browse

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(AppWorkspace.allCases) { workspace in
                    Button {
                        selectedWorkspace = workspace
                    } label: {
                        Label(workspace.title, systemImage: workspace.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                selectedWorkspace == workspace
                                ? Color(.systemGray5)
                                : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Bidpacket")
        } detail: {
            switch selectedWorkspace {
            case .browse:
                BrowseWorkspaceView(viewModel: viewModel)

            case .dashboard:
                DashboardWorkspaceView(viewModel: viewModel)

            case .downloads:
                PlaceholderWorkspaceView(
                    title: "Downloads",
                    message: "This will eventually show available bid packets to download for offline use.",
                    systemImage: "icloud.and.arrow.down"
                )

            case .settings:
                PlaceholderWorkspaceView(
                    title: "Settings",
                    message: "App preferences will live here.",
                    systemImage: "gearshape"
                )

            case .loginTest:
                LoginTestView(viewModel: viewModel)
            }
        }
        .task {
            viewModel.loadSample()
        }
    }
}

private enum AppWorkspace: String, CaseIterable, Identifiable {
    case browse
    case dashboard
    case downloads
    case settings
    case loginTest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browse: return "Browse"
        case .dashboard: return "Dashboard"
        case .downloads: return "Downloads"
        case .settings: return "Settings"
        case .loginTest: return "Login Test"
        }
    }

    var systemImage: String {
        switch self {
        case .browse: return "list.bullet.rectangle"
        case .dashboard: return "chart.bar"
        case .downloads: return "icloud.and.arrow.down"
        case .settings: return "gearshape"
        case .loginTest: return "lock.shield"
        }
    }
}
