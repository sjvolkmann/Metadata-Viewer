//
//  HistoryView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 23.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \HistoryEntry.versionDateTime, order: .reverse) private var historyEntries: [HistoryEntry]
    
    @Binding var showComparison: Bool
    @Binding var selectedHistoryListEntryId: UUID?
    @Binding var restoreQueue: [MetadataTag: Any?]
    
    var body: some View {
        HStack(spacing: 0) {
            if historyEntries.isEmpty {
                Text("Loading History…")
                    .font(.title2)
            } else {
                ScrollView {
                    ForEach(historyEntries) { historyEntry in
                        HistoryItemView(historyEntry: historyEntry, showComparison: $showComparison, selectedHistoryListEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(historyEntry)
                                    
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("Failed to delete history entry:", error)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .frame(width: 250)
                }
                .background(.quaternary.opacity(0.2))
            }
        }
        .frame(width: 250)
    }
}

#Preview {
    @Previewable @State var showComparison: Bool = false
    @Previewable @State var selectedHistoryListEntryId: UUID?
    @Previewable @State var restoreQueue: [MetadataTag: Any?] = [:]
    
    HistoryView(showComparison: $showComparison, selectedHistoryListEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue)
        .modelContainer(for: [
            HistoryEntry.self
        ])
        .frame(width: 250, height: 500)
}
