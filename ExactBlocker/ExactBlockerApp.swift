import SwiftUI
import SafariServices          // ← needed for the reload call

@main
struct ExactBlockerApp: App {
    @StateObject private var store = BlockStore()      // ⬅️ 1️⃣ create the model

    var body: some Scene {
        WindowGroup {
            BlockListView()                            // ⬅️ 2️⃣ show the list UI
                .environmentObject(store)
                // 3️⃣ every time the list changes, rebuild JSON & reload Safari
                .onChange(of: store.hosts) { _ in
                    store.writeRulesAndReload()
                }
                .onChange(of: store.elementRules) { _ in
                    store.writeRulesAndReload()
                }
        }
    }
}
