//
//  FilePathBarView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 24.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Places a text field in the toolbar to enter a file path or pick one from Finder.
/// On .leading a button to send a write command, on .trailing three buttons to get
/// a command to open either the raw tags, the comparison, or the history view.
///
/// - Parameter filePath: Set a URL in the text field or get the URL that was entered.
/// - Parameter filePathIsFocused: Manually remove the focus from the text field.
/// - Parameter readingWritingProgress: Set between 0...1 to display a
/// progress indicator below the text field. Receiving non-zero means write command.
/// - Parameter readingWritingStatus: Set a short text status of the progress.
/// - Parameter readingWritingStatusDate: Set the date of the last action.
struct FilePathBarView: ToolbarContent {
    let viewModel: MetadataViewModel?
    @Environment(\.modelContext) private var modelContext
    
    // Internal variables for this structure
    @State private var filePathText: String = ""
    @State private var hoverFilePicker: Bool = false
    @State private var filePathFieldTextWidth: CGFloat = 0
    @State private var showingFilePicker: Bool = false
    @State private var isConfirmingRestoreQueue = false
    
    // Variables managed by the main view to pass
    @Binding var filePath: URL?
    @FocusState.Binding var filePathIsFocused: Bool
    @Binding var readingWritingProgress: Double
    @Binding var readingWritingStatus: ReadingWritingStatus
    @Binding var readingWritingStatusDate: Date
    @Binding var showRawtags: Bool
    @Binding var showComparison: Bool
    @Binding var showHistory: Bool
    @Binding var selectedHistoryListEntryId: UUID?
    @Binding var restoreQueue: [MetadataTag: Any?]
    @Binding var metadataUpdate: [MetadataTag: Any?]
    
    @MainActor
    private func restoreQueuedHistory() {
        // Capture all values before the first await so they cannot change
        // underneath the restore operation while it is running.
        let queuedRestore = restoreQueue
        let queuedHistoryEntryId = selectedHistoryListEntryId
        
        Task {
            guard !queuedRestore.isEmpty else {
                readingWritingProgress = 0
                readingWritingStatusDate = .now
                readingWritingStatus = .failed
                
                return
            }
            
            guard let historyEntryId = queuedHistoryEntryId else {
                readingWritingProgress = 0
                readingWritingStatusDate = .now
                readingWritingStatus = .failed
                
                return
            }
            
            readingWritingProgress = 0.01
            readingWritingStatus = .scheduled
            
            do {
                // Fetch the actual HistoryEntry from SwiftData.
                let fetchDescriptor = FetchDescriptor<HistoryEntry>(
                    predicate: #Predicate<HistoryEntry> {
                        $0.id == historyEntryId
                    }
                )
                
                guard let historyEntry = try modelContext.fetch(fetchDescriptor).first else {
                    throw NSError(
                        domain: "MetadataViewer",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "The selected history entry could not be found."
                        ]
                    )
                }
                
                let historicFilePath = historyEntry.filePath
                
                // The target is a historic file, so verify it still exists
                // before doing anything else with it.
                guard FileManager.default.fileExists(atPath: historicFilePath.path) else {
                    throw MetadataServiceError.fileNotWritable
                }
                
                // raw is produced for reading only and must never be written.
                guard !queuedRestore.keys.contains(.raw) else {
                    throw NSError(
                        domain: "MetadataViewer",
                        code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "The raw metadata tag cannot be written."
                        ]
                    )
                }
                
                readingWritingProgress = 0.2
                readingWritingStatus = .building
                
                // Read the actual current state of the historic file.
                // This gives the new HistoryEntry an accurate previous version.
                let previousMetadata = try await MetadataService.read(
                    filePath: historicFilePath,
                    tags: metadataTagsAvailable
                )
                
                // Write exactly the queued tags.
                try await MetadataService.write(
                    filePath: historicFilePath,
                    metadata: queuedRestore
                )
                
                readingWritingProgress = 0.7
                
                // Record the successful restore in history.
                let newHistoryEntry = HistoryEntry(
                    filePath: historicFilePath,
                    versionPrevious: previousMetadata,
                    versionUpdate: queuedRestore
                )
                
                modelContext.insert(newHistoryEntry)
                
                do {
                    try modelContext.save()
                } catch {
                    // The file was already successfully written. Remove the
                    // unsaved history object so a retry cannot create a duplicate.
                    modelContext.delete(newHistoryEntry)
                    throw error
                }
                
                // Only clear the restore queue after the complete operation
                // including history persistence succeeded.
                restoreQueue = [:]
                
                try await Task.sleep(for: .seconds(0.3))
                
                readingWritingProgress = 0
                readingWritingStatusDate = .now
                readingWritingStatus = .finished
                
            } catch {
                readingWritingProgress = 0
                readingWritingStatusDate = .now
                readingWritingStatus = .failed
            }
        }
    }
    
    var body: some ToolbarContent {
        // Write metadata button
        ToolbarItem(placement: .navigation) {
            Button {
                // Restore always takes precedence over normal writing.
                if !restoreQueue.isEmpty {
                    isConfirmingRestoreQueue = true
                    return
                }
                
                Task {
                    // Capture all values before the first await so they cannot change
                    // underneath the write operation while it is running.
                    let currentFilePath = filePath
                    let pendingMetadata = metadataUpdate
                    let currentMetadata = viewModel?.metadataCurrent
                    
                    if !pendingMetadata.isEmpty {
                        guard let currentFilePath else {
                            readingWritingProgress = 0
                            readingWritingStatusDate = .now
                            readingWritingStatus = .failed
                            
                            return
                        }
                        
                        guard let currentMetadata else {
                            readingWritingProgress = 0
                            readingWritingStatusDate = .now
                            readingWritingStatus = .failed
                            
                            return
                        }
                        
                        // raw is produced for reading only and must never be written.
                        guard !pendingMetadata.keys.contains(.raw) else {
                            readingWritingProgress = 0
                            readingWritingStatusDate = .now
                            readingWritingStatus = .failed
                            
                            return
                        }
                        
                        readingWritingProgress = 0.01
                        readingWritingStatus = .scheduled
                        
                        do {
                            readingWritingProgress = 0.2
                            readingWritingStatus = .building
                            
                            // Write only the pending changes.
                            try await MetadataService.write(
                                filePath: currentFilePath,
                                metadata: pendingMetadata
                            )
                            
                            readingWritingProgress = 0.7
                            
                            let newHistoryEntry = HistoryEntry(
                                filePath: currentFilePath,
                                versionPrevious: currentMetadata,
                                versionUpdate: pendingMetadata
                            )
                            
                            modelContext.insert(newHistoryEntry)
                            
                            do {
                                try modelContext.save()
                            } catch {
                                modelContext.delete(newHistoryEntry)
                                throw error
                            }
                            
                            metadataUpdate = [:]
                            
                            // Reload the current file.
                            filePath = currentFilePath
                            
                            try await Task.sleep(for: .seconds(0.3))
                            
                            readingWritingProgress = 0
                            readingWritingStatusDate = .now
                            readingWritingStatus = .finished
                            
                        } catch {
                            // Keep metadataUpdate intact on failure so the operation
                            // can be retried instead of silently losing the changes.
                            readingWritingProgress = 0
                            readingWritingStatusDate = .now
                            readingWritingStatus = .failed
                        }
                        
                    } else {
                        return
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.down.on.square")
            }
            .help("Write metadata to the current file")
            .disabled(restoreQueue.isEmpty && metadataUpdate.isEmpty)
            .confirmationDialog(
                "An item from history is in the queue",
                isPresented: $isConfirmingRestoreQueue,
                titleVisibility: .visible
            ) {
                Button("Cancel", role: .cancel) {
                    readingWritingProgress = 0
                    readingWritingStatusDate = .now
                    readingWritingStatus = .cancelled
                }
                Button("Delete queued history entry", role: .destructive) {
                    restoreQueue = [:]
                    readingWritingProgress = 0
                    readingWritingStatusDate = .now
                    readingWritingStatus = .finished
                }
                Button("Restore the queued history entry", role: .confirm) {
                    restoreQueuedHistory()
                }
            } message: {
                Text("There are metadata tags selected from the history to restore to its respective file. Delete the queue or proceed restoring the selected metadata tags from the history first before writing to a new file.")
            }
        }
        if readingWritingStatus != .ready {
            ToolbarItem(placement: .navigation) {
                VStack {
                    HStack {
                        Text(readingWritingStatus.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    if readingWritingStatus != .scheduled &&
                        readingWritingStatus != .building {
                        HStack {
                            if Calendar.current.isDateInToday(readingWritingStatusDate) {
                                Text("Today at \(readingWritingStatusDate.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if Calendar.current.isDateInYesterday(readingWritingStatusDate) {
                                Text("Yesterday at \(readingWritingStatusDate.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(readingWritingStatusDate.formatted())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: 100)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        
        // File path bar
        ToolbarItem(placement: .principal) {
            ZStack(alignment: .leading) {
                TextField("", text: $filePathText)
                    .focused($filePathIsFocused)
                //.focusEffectDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .padding([.leading, .trailing], 22)
                    .foregroundStyle(hoverFilePicker ? .clear : .primary)
                    .mask {
                        LinearGradient(
                            colors: [.black, .black, .black, .black, .black, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        filePath = nil
                        filePathText = ""
                        
                        guard let provider = providers.first else {
                            return false
                        }
                        
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
                            guard let url else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                filePathText = url.path
                            }
                        }
                        
                        return true
                    }
                    .onChange(of: filePathText) {
                        filePath = URL(filePath: filePathText)
                    }
                    .onSubmit {
                        filePath = URL(filePath: filePathText)
                    }
                HStack {
                    Button(action: {
                        showingFilePicker.toggle()
                    }, label: {
                        Image(systemName: "photo")
                    })
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoverFilePicker = hovering
                        }
                    }
                    .fileImporter(
                        isPresented: $showingFilePicker,
                        allowedContentTypes: [.png, .jpeg, .tiff]
                    ) { result in
                        switch result {
                        case .success(let url):
                            filePathText = url.path
                            
                        case .failure(let error):
                            print(error)
                        }
                    }
                    if hoverFilePicker {
                        HStack {
                            Text("Browse file")
                                .allowsHitTesting(false)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .frame(width: filePathFieldTextWidth)
                    } else {
                        Text("Drag and drop file or enter file path")
                            .allowsHitTesting(false)
                            .opacity(filePathText.isEmpty ? 1 : 0)
                            .background {
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            filePathFieldTextWidth = geometry.size.width
                                        }
                                        .onChange(of: geometry.size.width) {
                                            filePathFieldTextWidth = geometry.size.width
                                        }
                                }
                            }
                    }
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: filePathIsFocused || !filePathText.isEmpty ? .leading : .center)
                .padding(.horizontal, 10)
                .animation(.easeInOut(duration: 0.2), value: filePathIsFocused)
                if filePathIsFocused, !filePathText.isEmpty {
                    Button {
                        filePathText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                } else if !filePathText.isEmpty {
                    Button {
                        filePath = URL(filePath: filePathText)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                }
                if readingWritingProgress != 0 {
                    ProgressView(value: readingWritingProgress)
                        .progressViewStyle(.linear)
                        .scaleEffect(y: 0.3)
                        .offset(y: 16.5)
                        .allowsHitTesting(false)
                }
            }
            .frame(minWidth: 350, idealWidth: 500, maxWidth: 700)
        }
        
        // Show raw data, comparision, history view
        ToolbarItemGroup(placement: .primaryAction) {
            HStack(spacing: 0) {
                Toggle(isOn: $showRawtags) {
                    Image(systemName: "ellipsis.curlybraces")
                }
                .help("Show raw metadata tags")
                .onChange(of: showRawtags, {
                    if showRawtags {
                        showComparison = false
                    }
                })
                Divider()
                    .frame(height: 20)
                Toggle(isOn: $showComparison) {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .help("Show comparison")
                .onChange(of: showComparison, {
                    if showComparison {
                        showRawtags = false
                    }
                })
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(placement: .primaryAction) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showHistory.toggle()
                }
            } label: {
                Image(systemName: "sidebar.trailing")
            }
            .help("Show history")
        }
    }
}

#Preview {
    @Previewable @State var viewModel = MetadataViewModel()
    @Previewable @State var filePath: URL?
    @Previewable @FocusState var filePathIsFocused: Bool
    @Previewable @State var readingWritingProgress: Double = 0.2
    @Previewable @State var readingWritingStatus: ReadingWritingStatus = .finished
    @Previewable @State var readingWritingStatusDate: Date = Date()
    @Previewable @State var showRawtags: Bool = false
    @Previewable @State var showComparison: Bool = false
    @Previewable @State var showHistory: Bool = false
    @Previewable @State var selectedHistoryListEntryId: UUID?
    @Previewable @State var restoreQueue: [MetadataTag: Any?] = [:]
    @Previewable @State var metadataUpdate: [MetadataTag: Any?] = [:]
    
    HStack { }
        .frame(width: 900, height: 500)
        .toolbar {
            FilePathBarView(viewModel: viewModel, filePath: $viewModel.filePath, filePathIsFocused: $filePathIsFocused, readingWritingProgress: $readingWritingProgress, readingWritingStatus: $readingWritingStatus, readingWritingStatusDate: $readingWritingStatusDate, showRawtags: $showRawtags, showComparison: $showComparison, showHistory: $showHistory, selectedHistoryListEntryId: $selectedHistoryListEntryId, restoreQueue: $restoreQueue, metadataUpdate: $metadataUpdate)
        }
        .toolbar(removing: .title)
        .modelContainer(for: [
            HistoryEntry.self
        ])
}
