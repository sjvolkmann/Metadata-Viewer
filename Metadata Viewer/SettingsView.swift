//
//  SettingsView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 19.09.2026.
//

import SwiftUI

struct SettingsView: View {
    private static let year = Calendar.current.component(.year, from: Date())
    @AppStorage("copyrightString") private var copyrightString: String = "Copyright © \(year) Killarnee. All rights reserved."
    @AppStorage("exiftoolBinary") private var exiftoolBinary: String = "/opt/homebrew/bin/exiftool"
    
    var body: some View {
        Grid {
            GridRow {
                Text("Exiftool binary path")
                    .gridColumnAlignment(.trailing)
                TextField("File path", text: $exiftoolBinary)
                    .gridColumnAlignment(.leading)
            }
            GridRow {
                Text("Copyright metadata")
                TextField("Copyright © 2026 Killarnee. All rights reserved.", text: $copyrightString)
                
            }
        }
        .padding()
        .frame(width: 500, height: 100)
    }
}

#Preview {
    SettingsView()
}
