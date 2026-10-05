//
//  MetadataViewerApp.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 18.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftData
import SwiftUI

@main
struct MetadataViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 523, idealHeight: 653.75)
        }
        .modelContainer(for: [
            HistoryEntry.self,
            KeywordsPresetsSingle.self,
            KeywordsPresetsMulti.self
        ])
        
        Settings {
            SettingsView()
        }
    }
}
