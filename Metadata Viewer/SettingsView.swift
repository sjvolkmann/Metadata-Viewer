//
//  SettingsView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 19.09.2026.
//

import SwiftUI

struct SettingsView: View {
    private static let year = Calendar.current.component(.year, from: Date())
    private static let exiftoolBinaryDefaultPath = "/opt/homebrew/bin/exiftool"
    private static let bundleCopyrightString = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © \(year) Killarnee. All rights reserved."
    
    @State private var exiftoolBinarySheetPresented = false
    
    @AppStorage("copyrightString") private var copyrightString: String = bundleCopyrightString
    @AppStorage("exiftoolBinary") private var exiftoolBinary: String = exiftoolBinaryDefaultPath
    
    var body: some View {
        List {
            Section {
                VStack {
                    HStack {
                        Text("Exiftool binary path")
                        Spacer()
                        if exiftoolBinary == Self.exiftoolBinaryDefaultPath {
                            Text("Default")
                        } else {
                            Text("Custom")
                        }
                        Button {
                            exiftoolBinarySheetPresented.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    HStack {
                        Text(exiftoolBinary)
                            .foregroundStyle(.secondary)
                        Button {
                            let url = URL(fileURLWithPath: exiftoolBinary)
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        } label: {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                .padding([.top, .bottom], 5)
                .sheet(isPresented: $exiftoolBinarySheetPresented) {
                    VStack {
                        VStack {
                            VStack {
                                HStack {
                                    Text("Exiftool binary path")
                                    Spacer()
                                }
                                TextField("", text: $exiftoolBinary)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.06))
                            )
                        .padding([.leading, .trailing, .top])
                        Divider()
                        HStack {
                            Spacer()
                            Button("Done") {
                                exiftoolBinarySheetPresented = false
                            }
                        }
                        .padding([.leading, .trailing, .bottom])
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.06))
                )
            Section {
                VStack {
                    HStack {
                        Text("Metadata copyright text")
                        Spacer()
                    }
                    Divider()
                    TextField(Self.bundleCopyrightString, text: $copyrightString)
                        .textFieldStyle(.roundedBorder)
                }
                .padding([.top, .bottom], 5)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.06))
                )
        }
        .padding()
        .frame(width: 500, height: 200)
    }
}

#Preview {
    SettingsView()
}
