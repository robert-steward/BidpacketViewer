import SwiftUI

struct DownloadsWorkspaceView: View {
    @Bindable var viewModel: BidpacketViewModel

    @AppStorage("alpaUsername") private var username = ""
    @AppStorage("alpaPassword") private var password = ""

    @State private var statusMessage = "Not connected"
    @State private var isLoading = false
    @State private var downloadingFileName: String?
    
    @State private var selectedBase = "ATL"
    @State private var remoteFiles: [RemoteBidpacketFile] = []
    @State private var localFiles: [URL] = []

    private let bases = ["ATL", "BOS", "DTW", "LAX", "MSP", "NYC", "SEA", "SLC"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                loginSection
                remoteBidpacketSection
                localBidpacketSection
                statusSection
            }
            .padding(28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Downloads")
        .task {
            refreshLocalFiles()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Download bid packets for offline use.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Alpa Login")
                .font(.headline)
            Text("Use your ALPA credentials to access bidpacket downloads.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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

    private var remoteBidpacketSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Available Bid Packets")
                    .font(.headline)

                Spacer()

                Button(isLoading ? "Refreshing..." : "Refresh List") {
                    refreshRemoteBidpackets()
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)
            }

            Picker("Base", selection: $selectedBase) {
                ForEach(bases, id: \.self) { base in
                    Text(base).tag(base)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 620)
            .onChange(of: selectedBase) {
                remoteFiles = []

                if !username.isEmpty && !password.isEmpty {
                    refreshRemoteBidpackets()
                }
            }

            if remoteFiles.isEmpty {
                Text("No remote bid packets loaded yet. Choose a base and tap Refresh List.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(remoteFiles) { file in
                        remoteFileRow(file)
                    }
                }
            }

            Text("Server list: /site_content/list_bidpackets.php?base=\(selectedBase)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func remoteFileRow(_ file: RemoteBidpacketFile) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(file.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(file.name)
                    Text("•")
                    Text(file.sizeText)

                    if let modified = file.modified {
                        Text("•")
                        Text(modified)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if isDownloaded(file) {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else {
                Button(downloadingFileName == file.name ? "Downloading..." : "Download") {
                    downloadBidpacket(file)
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var localBidpacketSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Downloaded Bid Packets")
                    .font(.headline)

                Spacer()

                Button("Refresh") {
                    refreshLocalFiles()
                }
            }

            if localFiles.isEmpty {
                Text("No downloaded bid packets yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(localFiles, id: \.lastPathComponent) { fileURL in
                        localFileRow(fileURL)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func localFileRow(_ fileURL: URL) -> some View {
        let fileName = fileURL.lastPathComponent
        let isActive = LocalBidpacketStore.activeBidpacketFileName() == fileName

        return HStack(spacing: 14) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isActive ? .blue : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.headline)

                Text(isActive ? "Active bidpacket" : "Downloaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isActive {
                Button("Load") {
                    loadBidpacket(fileName: fileName)
                }
            }

            Button(role: .destructive) {
                deleteLocalBidpacket(fileURL)
            } label: {
                Text("Delete")
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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

    private func refreshRemoteBidpackets() {
        isLoading = true
        statusMessage = "Fetching bidpacket list for \(selectedBase)..."

        Task {
            do {
                let service = BidpacketDownloadService(
                    username: username,
                    password: password
                )

                let files = try await service.listBidpackets(base: selectedBase)

                await MainActor.run {
                    remoteFiles = files
                    isLoading = false
                    statusMessage = "Loaded \(files.count) available bidpacket(s) for \(selectedBase)."
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    remoteFiles = []
                    statusMessage = """
                    Unable to retrieve the bidpacket list.

                    \(error.localizedDescription)

                    Please verify your ALPA username and password and try again. If the problem persists, the server may be temporarily unavailable.
                    """
                }
            }
        }
    }

    private func downloadBidpacket(_ file: RemoteBidpacketFile) {
        isLoading = true
        downloadingFileName = file.name
        statusMessage = "Downloading \(file.name)..."

        Task {
            do {
                let service = BidpacketDownloadService(
                    username: username,
                    password: password
                )

                let data = try await service.downloadBidpacket(
                    base: selectedBase,
                    fileName: file.name
                )

                let savedURL = try LocalBidpacketStore.save(
                    data,
                    fileName: downloadedFileName(for: file)
                )
                
                LocalBidpacketStore.setActiveBidpacket(
                    fileName: savedURL.lastPathComponent
                )

                await MainActor.run {
                    isLoading = false
                    downloadingFileName = nil

                    loadBidpacket(fileName: savedURL.lastPathComponent)

                    var output = ""
                    output += "Downloaded \(data.count) bytes\n"
                    output += "Saved as \(savedURL.lastPathComponent)\n"
                    output += "Set as active bidpacket\n"
                    output += "Loaded bidpacket\n"

                    statusMessage = output
                }

            } catch {
                await MainActor.run {
                    
                    isLoading = false
                    downloadingFileName = nil
                    statusMessage = "Download failed:\n\(error.localizedDescription)"
                }
            }
        }
    }

    private func loadActiveBidpacket() {
        do {
            let fileName = LocalBidpacketStore.activeBidpacketFileName()
                ?? "sample_bidpacket.json"

            try loadBidpacketFromStorage(fileName: fileName)

            statusMessage = "Loaded active bidpacket: \(fileName)"
        } catch {
            statusMessage = "Load failed:\n\(error.localizedDescription)"
        }
    }

    private func loadBidpacket(fileName: String) {
        do {
            LocalBidpacketStore.setActiveBidpacket(fileName: fileName)
            try loadBidpacketFromStorage(fileName: fileName)

            refreshLocalFiles()
            statusMessage = "Loaded bidpacket: \(fileName)"
        } catch {
            statusMessage = "Load failed:\n\(error.localizedDescription)"
        }
    }

    private func loadBidpacketFromStorage(fileName: String) throws {
        let data = try LocalBidpacketStore.load(fileName: fileName)
        viewModel.loadFromData(data)
    }

    private func refreshLocalFiles() {
        do {
            localFiles = try LocalBidpacketStore.localFiles()
        } catch {
            statusMessage = "Failed to refresh local files:\n\(error.localizedDescription)"
        }
    }

    private func downloadedFileName(for file: RemoteBidpacketFile) -> String {
        "\(selectedBase)_\(file.name)"
    }

    private func isDownloaded(_ file: RemoteBidpacketFile) -> Bool {
        let expectedFileName = downloadedFileName(for: file)

        return localFiles.contains { localFile in
            localFile.lastPathComponent == expectedFileName
        }
    }
    
    private func deleteLocalBidpacket(_ fileURL: URL) {
        let fileName = fileURL.lastPathComponent

        do {
            try FileManager.default.removeItem(at: fileURL)

            if LocalBidpacketStore.activeBidpacketFileName() == fileName {
                LocalBidpacketStore.setActiveBidpacket(fileName: "")
            }

            refreshLocalFiles()
            statusMessage = "Deleted \(fileName)"
        } catch {
            statusMessage = "Delete failed:\n\(error.localizedDescription)"
        }
    }
}

#Preview {
    DownloadsWorkspaceView(viewModel: BidpacketViewModel())
}
