//
//  RawTagsView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 23.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftUI

struct RawTagsView: View {
    let viewModel: MetadataViewModel
    
    @State private var sortOrder: [KeyPathComparator<MetadataItem>] = []
    @State private var selectedItems: Set<MetadataItem.ID> = []
    
    var body: some View {
        VStack {
            if let metadata = viewModel.metadataCurrent?[.raw] as? [String: Any] {
                let items = metadata.map {
                    MetadataItem(
                        id: $0.key,
                        key: $0.key,
                        value: String(describing: $0.value)
                    )
                }
                
                Table(
                    items.sorted(using: sortOrder),
                    selection: $selectedItems,
                    sortOrder: $sortOrder
                ) {
                    TableColumn("Key", value: \.key)
                    TableColumn("Value", value: \.value)
                }
                .focusable()
                .onKeyPress(.init("c"), phases: .down) { keyPress in
                    guard keyPress.modifiers.contains(.command) else {
                        return .ignored
                    }
                    
                    let string = items
                        .filter { selectedItems.contains($0.id) }
                        .map { "\($0.key): \($0.value)" }
                        .joined(separator: "\n")
                    
                    guard !string.isEmpty else {
                        return .handled
                    }
                    
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(string, forType: .string)
                    
                    return .handled
                }
                .frame(maxWidth: 800)
            } else {
                Text("Metadata could not load.")
                    .font(.title2)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

struct MetadataItem: Identifiable, Hashable {
    let id: String
    let key: String
    var value: String
}

#Preview {
    @Previewable @State var viewModel = MetadataViewModel()
    
    RawTagsView(viewModel: viewModel)
}
