//
//  jobTrackerApp.swift
//  jobTracker
//
//  Created by Preet Singh on 2/3/26.
//

import SwiftUI

@main
struct JobTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
