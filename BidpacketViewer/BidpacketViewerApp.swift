import SwiftUI

@main
struct BidpacketViewerApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = "day"

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(
                    appearanceMode == "night" ? .dark : .light
                )
        }
    }
}
