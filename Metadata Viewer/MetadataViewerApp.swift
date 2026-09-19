//
//  MetadataViewerApp.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 18.09.2026.
//

import SwiftUI

@main
struct MetadataViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
    }
}
