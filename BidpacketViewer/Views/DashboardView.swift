import SwiftUI

struct DashboardView: View {
    @State private var viewModel = BidpacketViewModel()
    @State private var selectedWorkspace: AppWorkspace = .browse
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
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
                DownloadsWorkspaceView(viewModel: viewModel)
                
            case .glossary:
                GlossaryWorkspaceView()

                
            case .settings:
                SettingsWorkspaceView()

            
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
    case glossary
    case settings
    

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browse: return "Rotations"
        case .dashboard: return "Dashboard"
        case .downloads: return "Downloads"
        case .glossary: return "Glossary"
        case .settings: return "Settings"
        
        }
    }

    var systemImage: String {
        switch self {
        case .browse: return "list.bullet.rectangle"
        case .dashboard: return "chart.bar"
        case .downloads: return "icloud.and.arrow.down"
        case .glossary: return "book.closed"
        case .settings: return "gearshape"
        
        }
    }
}
