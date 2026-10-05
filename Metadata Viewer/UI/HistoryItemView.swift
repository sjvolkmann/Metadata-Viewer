//
//  HistoryItemView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 23.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftUI

struct HistoryItemView: View {
    let historyEntry: HistoryEntry
    @Binding var showComparison: Bool
    @Binding var selectedHistoryListEntryId: UUID?
    @Binding var restoreQueue: [MetadataTag: Any?]
    
    @State private var popoverActiveForHistoryEntryId: UUID?
    @State private var popoverActionSelection: Int = 0
    
    var body: some View {
        let newTags = historyEntry.versionUpdate.filter { key, value in
            !historyEntry.versionPrevious.keys.contains(key)
            && value != nil
        }
        
        let removedTags = historyEntry.versionUpdate.filter { key, value in
            historyEntry.versionPrevious.keys.contains(key)
            && value == nil
        }
        
        let changedTags = historyEntry.versionUpdate.filter { key, value in
            historyEntry.versionPrevious.keys.contains(key)
            && value != nil
        }
        
        return Button {
            if selectedHistoryListEntryId != historyEntry.id {
                selectedHistoryListEntryId = historyEntry.id
                popoverActiveForHistoryEntryId = historyEntry.id
            } else {
                selectedHistoryListEntryId = nil
                popoverActiveForHistoryEntryId = nil
            }
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(historyEntry.filePath.path)
                    Spacer()
                }
                HStack {
                    if historyEntry.versionUpdate.count == 1 {
                        Text("1 change")
                    } else {
                        Text("\(historyEntry.versionUpdate.count) changes")
                    }
                    Spacer()
                    Text(historyEntry.versionDateTime.formatted())
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .fontWeight(.light)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .background(
            selectedHistoryListEntryId == historyEntry.id
            ? .blue.opacity(0.2)
            : .clear
        )
        .popover(
            isPresented: Binding(
                get: {
                    popoverActiveForHistoryEntryId == historyEntry.id
                },
                set: { isPresented in
                    if !isPresented {
                        popoverActiveForHistoryEntryId = nil
                    }
                }
            ),
            arrowEdge: .trailing
        ) {
            VStack {
                HStack {
                    Image(systemName: "photo")
                        .padding([.leading, .trailing], 4)
                    
                    Text(historyEntry.filePath.path)
                }
                .font(.title3)
                .lineLimit(1)
                .truncationMode(.head)
                .padding(7)
                .frame(width: 280)
                .background(.quaternary, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.separator, lineWidth: 1)
                }
                
                ScrollView {
                    Group {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("^[\(historyEntry.versionUpdate.count) total changed metadata tag](inflect: true)")
                            Divider()
                            Text("^[\(changedTags.count) changed metadata tag](inflect: true)")
                            Divider()
                            Text("^[\(newTags.count) new metadata tag](inflect: true)")
                            Divider()
                            Text("^[\(removedTags.count) removed metadata tag](inflect: true)")
                            Divider()
                        }
                        .font(.callout)
                        .padding([.top, .horizontal])
                        VStack {
                            ForEach(historyEntry.versionUpdate.sorted { $0.key.rawValue < $1.key.rawValue }, id: \.key) { versionUpdateItem in
                                HStack {
                                    Text(versionUpdateItem.key.rawValue)
                                    Spacer()
                                    if versionUpdateItem.value == nil {
                                        Text("Deleted")
                                    } else if !historyEntry.versionPrevious.keys.contains(versionUpdateItem.key) {
                                        Text("Created")
                                    } else {
                                        Text("Updated")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(.quinary)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .padding(.horizontal)
                }
                .foregroundStyle(.primary)
                .frame(width: 300, height: 105)
                
                List(selection: $popoverActionSelection) {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([historyEntry.filePath])
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                                .padding([.leading, .trailing], 4)
                            Text("Show in Finder")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .onHover { _ in
                        popoverActionSelection = 0
                    }
                    .tag(0)
                    
                    Button {
                        showComparison = true
                        selectedHistoryListEntryId = historyEntry.id
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .padding([.leading, .trailing], 4)
                            Text("Compare versions")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .onHover { _ in
                        popoverActionSelection = 1
                    }
                    .tag(1)
                    
                    Button {
                        var restore: [MetadataTag: Any?] = [:]
                        
                        for tag in MetadataTag.allCases where tag != .raw {
                            if let value = historyEntry.versionPrevious[tag] {
                                restore[tag] = value
                            } else {
                                restore[tag] = nil
                            }
                        }
                        
                        restoreQueue = restore
                        showComparison = true
                        selectedHistoryListEntryId = historyEntry.id
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                .padding([.leading, .trailing], 4)
                            Text("Restore preceding version")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .onHover { _ in
                        popoverActionSelection = 2
                    }
                    .tag(2)
                }
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
            .frame(width: 300, height: 250)
            .padding(.top, 10)
        }
    }
}

#Preview {
    @Previewable var historyEntry: HistoryEntry = HistoryEntry(
        filePath: URL(fileURLWithPath: "/test/file.png"),
        versionPrevious: [
            .gpsSpeed: 234,
            .iptcObjectname: "Old object name"
        ],
        versionUpdate: [
            .gpsSpeed: nil,
            .iptcObjectname: "New object name",
            .ifd0ImageDescription: "Set description"
        ]
    )
    @Previewable @State var showComparison = false
    @Previewable @State var selectedHistoryListEntryId: UUID?
    @Previewable @State var restoreQueue: [MetadataTag: Any?] = [:]
    
    HistoryItemView(historyEntry: historyEntry, showComparison: $showComparison, selectedHistoryListEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue)
}
