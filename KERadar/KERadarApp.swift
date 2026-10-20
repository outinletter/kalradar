import SwiftUI

@main struct KERadarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = RadarStore()
    var body: some Scene {
        WindowGroup { RadarView().environmentObject(store).preferredColorScheme(.light).tint(Theme.mint).task { store.refreshIfNeeded() }.onChange(of: scenePhase) { _, phase in if phase == .active { store.refreshIfNeeded() } } }
    }
}
