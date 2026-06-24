import SwiftUI

struct DownloadsWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    @State private var username = ""
    @State private var password = ""

    @State private var statusMessage = "Not connected"
    @State private var isLoading = false

    private let testDownloadURL = "https://rotationscorer.alpa.org/bidpackets/sample_bidpacket.json"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            loginSection
            downloadSection
            statusSection

            Spacer()
        }
        .padding(28)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Downloads")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Downloads")
                .font(.largeTitle.bold())

            Text("Log in to download bid packets for offline use.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Server Login")
                .font(.headline)

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(maxWidth: 420)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Available Bid Packets")
                .font(.headline)

            Text("For now this uses the existing test JSON file. Next step will be listing available files from the server.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(isLoading ? "Downloading..." : "Download Test Bidpacket") {
                    downloadTestBidpacket()
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)

                Button("Load Active Bidpacket") {
                    loadActiveBidpacket()
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)

            ScrollView {
                Text(statusMessage)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 240)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func downloadTestBidpacket() {
        isLoading = true
        statusMessage = "Connecting..."

        Task {
            do {
                let service = BidpacketDownloadService(
                    username: username,
                    password: password
                )

                let data = try await service.downloadBidpacket(
                    from: testDownloadURL
                )

                let savedURL = try LocalBidpacketStore.save(
                    data,
                    fileName: "sample_bidpacket.json"
                )

                LocalBidpacketStore.setActiveBidpacket(
                    fileName: savedURL.lastPathComponent
                )

                await MainActor.run {
                    isLoading = false

                    var output = ""
                    output += "Downloaded \(data.count) bytes\n"
                    output += "Saved as \(savedURL.lastPathComponent)\n"
                    output += "Set as active bidpacket\n\n"

                    if let preview = String(data: data.prefix(500), encoding: .utf8) {
                        output += "Preview:\n\(preview)"
                    }

                    statusMessage = output
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "ERROR:\n\(error.localizedDescription)"
                }
            }
        }
    }

    private func loadActiveBidpacket() {
        do {
            let fileName = LocalBidpacketStore.activeBidpacketFileName()
                ?? "sample_bidpacket.json"

            let data = try LocalBidpacketStore.load(fileName: fileName)

            viewModel.loadFromData(data)

            statusMessage = "Loaded active bidpacket: \(fileName)"
        } catch {
            statusMessage = "Load failed:\n\(error.localizedDescription)"
        }
    }
}

#Preview {
    DownloadsWorkspaceView(viewModel: BidpacketViewModel())
}
