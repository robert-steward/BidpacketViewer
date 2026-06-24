import SwiftUI

struct SettingsWorkspaceView: View {
    @AppStorage("pilotBase") private var pilotBase: String = "LAX"

    private let bases = ["ATL", "BOS", "DTW", "LAX", "MSP", "NYC", "SEA", "SLC"]

    var body: some View {
        Form {
            Section("Pilot") {
                Picker("Home Base", selection: $pilotBase) {
                    ForEach(bases, id: \.self) { base in
                        Text(base).tag(base)
                    }
                }

                Text("This is your pilot home base. It will be used later for downloads, defaults, and commute-related features.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Data") {
                Button(role: .destructive) {
                    clearSavedSelections()
                } label: {
                    Text("Clear Saved Selected Rotations")
                }

                Text("This clears saved selected rotations from this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                LabeledContent("App", value: "BidpacketViewer")
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
    }

    private func clearSavedSelections() {
        let defaults = UserDefaults.standard

        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("selected_rotations_") {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
