//
//  ContentView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 18.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    // Toolbar
    @State var filePath: URL?
    @FocusState var filePathIsFocused: Bool
    @State var readingWritingProgress: Double = 0
    @State var readingWritingStatus: ReadingWritingStatus = .ready
    @State var readingWritingStatusDate: Date = .now
    @State var showRawtags: Bool = false
    @State var showComparison: Bool = false
    @State var showHistory: Bool = false
    @State var selectedHistoryListEntryId: UUID?
    @State private var restoreQueue: [MetadataTag: Any?] = [:]
    
    // Metadata
    @State var viewModel = MetadataViewModel()
    @State private var metadataUpdate: [MetadataTag: Any?] = [:]
    
    var body: some View {
        HStack(spacing: 0) {
            if showRawtags {
                RawTagsView(viewModel: viewModel)
            } else if showComparison {
                if selectedHistoryListEntryId != nil {
                    ComparisonView(historyEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue)
                } else {
                    ComparisonView(viewModel: viewModel, metadataUpdate: $metadataUpdate)
                }
            } else {
                EditView(viewModel: viewModel, metadataUpdate: $metadataUpdate)
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    filePathIsFocused = false
                }
        )
        .frame(minWidth: 800, minHeight: 523)
        .inspector(isPresented: $showHistory) {
            HistoryView(showComparison: $showComparison, selectedHistoryListEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .inspectorColumnWidth(250)
        }
        .toolbar {
            FilePathBarView(viewModel: viewModel, filePath: $viewModel.filePath, filePathIsFocused: $filePathIsFocused, readingWritingProgress: $readingWritingProgress, readingWritingStatus: $readingWritingStatus, readingWritingStatusDate: $readingWritingStatusDate, showRawtags: $showRawtags, showComparison: $showComparison, showHistory: $showHistory, selectedHistoryListEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue, metadataUpdate: $metadataUpdate)
        }
        .toolbar(removing: .title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            HistoryEntry.self,
            KeywordsPresetsSingle.self,
            KeywordsPresetsMulti.self
        ])
}
