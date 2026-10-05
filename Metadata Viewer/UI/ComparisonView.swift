//
//  ComparisonView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 23.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftData
import SwiftUI

struct ComparisonView: View {
    let viewModel: MetadataViewModel?
    @Binding var metadataUpdate: [MetadataTag: Any?]
    @Binding var historyEntryId: UUID?
    @Binding var restoreQueue: [MetadataTag: Any?]
    
    @Environment(\.modelContext) private var modelContext
    @State private var historyEntry: HistoryEntry?
    @State private var hiddenItems: Set<MetadataTag> = []
    
    init(
        viewModel: MetadataViewModel,
        metadataUpdate: Binding<[MetadataTag: Any?]>
    ) {
        self.viewModel = viewModel
        self._metadataUpdate = metadataUpdate
        self._historyEntryId = .constant(nil)
        self._restoreQueue = .constant([:])
    }
    
    init(
        historyEntryId: Binding<UUID?>,
        restoreQueue: Binding<[MetadataTag: Any?]>
    ) {
        self.viewModel = nil
        self._metadataUpdate = .constant([:])
        self._historyEntryId = historyEntryId
        self._restoreQueue = restoreQueue
    }
    
    private var currentFileHistoryEntry: HistoryEntry? {
        guard let viewModel else {
            return nil
        }
        
        return HistoryEntry(
            filePath: viewModel.filePath ?? URL(fileURLWithPath: "/dev/null"),
            versionPrevious: viewModel.metadataCurrent ?? [:],
            versionUpdate: metadataUpdate
        )
    }
    
    private var displayedHistoryEntry: HistoryEntry? {
        if historyEntryId != nil {
            return historyEntry
        }
        
        return currentFileHistoryEntry
    }
    
    private func metadataValueString(_ value: Any) -> String {
        if let array = value as? [Any] {
            return array.map { String(describing: $0) }.joined(separator: ", ")
        }
        
        if let array = value as? NSArray {
            return array
                .map { String(describing: $0) }
                .joined(separator: ", ")
        }
        
        return String(describing: value)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if historyEntryId != nil {
                HStack {
                    Text("You're seeing a history entry.")
                    
                    Button {
                        historyEntryId = nil
                    } label: {
                        Text("Back to the current file.")
                            .foregroundStyle(Color.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
            }
            
            if let historyEntry = displayedHistoryEntry,
               !historyEntry.versionUpdate.isEmpty {
                
                ScrollView {
                    let metadataCurrent = historyEntry.versionPrevious
                    
                    ForEach(
                        historyEntry.versionUpdate.keys
                            .filter { !hiddenItems.contains($0) }
                            .sorted { $0.rawValue < $1.rawValue },
                        id: \.self
                    ) { metadataUpdateItem in
                        VStack {
                            HStack {
                                HStack {
                                    Text(metadataUpdateItem.rawValue)
                                    
                                    if metadataValueString(restoreQueue[metadataUpdateItem] as Any)
                                        == metadataValueString(historyEntry.versionUpdate[metadataUpdateItem] as Any) {
                                        Text("Awaiting for restore")
                                            .foregroundStyle(.green)
                                    } else if restoreQueue.keys.contains(metadataUpdateItem) {
                                        Text("In restore queue with another value")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if historyEntryId != nil {
                                    if restoreQueue.keys.contains(metadataUpdateItem) {
                                        Button {
                                            restoreQueue.removeValue(
                                                forKey: metadataUpdateItem
                                            )
                                        } label: {
                                            Image(systemName: "xmark.square")
                                        }
                                        .buttonStyle(.plain)
                                        .help("Cancel restoring metadata")
                                    } else {
                                        Button {
                                            if let value = historyEntry.versionPrevious[metadataUpdateItem] {
                                                restoreQueue[metadataUpdateItem] = value
                                            } else {
                                                restoreQueue.updateValue(
                                                    nil,
                                                    forKey: metadataUpdateItem
                                                )
                                            }
                                        } label: {
                                            Image(
                                                systemName:
                                                    "clock.arrow.trianglehead.counterclockwise.rotate.90"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .help("Restore metadata")
                                    }
                                } else {
                                    Button {
                                        hiddenItems.insert(metadataUpdateItem)
                                        metadataUpdate.removeValue(
                                            forKey: metadataUpdateItem
                                        )
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.plain)
                                    .help("Revert changed metadata")
                                }
                            }
                            
                            Spacer()
                            
                            Grid(alignment: .leading) {
                                GridRow {
                                    Text("Current")
                                    Text("New")
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                
                                GridRow {
                                    if let currentValue = metadataCurrent[metadataUpdateItem] {
                                        Text(metadataValueString(currentValue))
                                            .textSelection(.enabled)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(
                                                horizontal: false,
                                                vertical: true
                                            )
                                            .padding(8)
                                            .background(.quaternary)
                                    } else {
                                        Text("Created")
                                            .italic()
                                            .foregroundStyle(.secondary)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                            .padding(8)
                                            .background(.quaternary)
                                    }
                                    
                                    if let updatedValue = historyEntry.versionUpdate[metadataUpdateItem] ?? nil {
                                        Text(metadataValueString(updatedValue as Any))
                                            .textSelection(.enabled)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(
                                                horizontal: false,
                                                vertical: true
                                            )
                                            .padding(8)
                                            .background(.quaternary)
                                    } else {
                                        Text("Deleted")
                                            .italic()
                                            .foregroundStyle(.secondary)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                            .padding(8)
                                            .background(.quaternary)
                                    }
                                }
                            }
                        }
                        .padding(8)
                        .frame(minHeight: 90)
                        .background(
                            .quaternary,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .padding([.leading, .trailing])
                        .padding([.top, .bottom], 6)
                    }
                    .padding(.top, 10)
                }
            } else {
                Text("No differences")
                    .font(.title2)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .task(id: historyEntryId) {
            hiddenItems = []
            
            guard let historyEntryId else {
                historyEntry = nil
                return
            }
            
            let descriptor = FetchDescriptor<HistoryEntry>(
                predicate: #Predicate { entry in
                    entry.id == historyEntryId
                }
            )
            
            do {
                historyEntry = try modelContext.fetch(descriptor).first
            } catch {
                historyEntry = nil
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = MetadataViewModel()
    @Previewable @State var metadataUpdate: [MetadataTag: Any?] = [
        .ifd0ImageDescription: "This description will overwrite the old description",
        .iptcObjectname: "New object name",
        .gpsSpeed: nil
    ]
    @Previewable @State var restoreQueue: [MetadataTag: Any?] = [:]
    @Previewable @State var historyEntryId: UUID? = UUID()
    
    // ComparisonView(
    //     viewModel: viewModel,
    //     metadataUpdate: $metadataUpdate
    // )
    
    ComparisonView(
        historyEntryId: $historyEntryId,
        restoreQueue: $restoreQueue
    )
    .modelContainer(for: [
        HistoryEntry.self
    ])
}
