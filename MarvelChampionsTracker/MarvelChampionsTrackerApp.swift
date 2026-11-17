import SwiftUI

@main
struct MarvelChampionsTrackerApp: App {
    @StateObject private var store = TrackerStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(Theme.navy)
        }
    }
}

enum Theme {
    static let navy = Color(red: 0.10, green: 0.16, blue: 0.25)
    static let red = Color(red: 0.76, green: 0.20, blue: 0.23)
    static let blue = Color(red: 0.20, green: 0.43, blue: 0.67)
    static let gold = Color(red: 0.72, green: 0.54, blue: 0.22)
    static let canvas = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let panel = Color.white
    static let muted = Color(red: 0.43, green: 0.46, blue: 0.50)
}
