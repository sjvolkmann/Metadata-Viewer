//
//  EditSheetKeywordsView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 27.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftData
import SwiftUI

struct EditSheetKeywordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let keywordsStandardView: Bool
    let viewModel: MetadataViewModel?
    @Binding var metadataUpdate: [MetadataTag: Any?]
    let metadataTag: MetadataTag
    
    @State private var pendingKeywordsUpdate: [String]?
    @State private var newKeyword: String?
    @AppStorage("presetsSingleSelected") private var presetsSingleSelected: Bool = true
    @Query private var presetsSingle: [KeywordsPresetsSingle]
    @State private var newPresetsSingle: String?
    @Query private var presetsMulti: [KeywordsPresetsMulti]
    @State private var newPresetsMulti: String?
    
    private var keywords: [String] {
        if let pendingKeywordsUpdate {
            return pendingKeywordsUpdate
        }
        
        if metadataUpdate.keys.contains(metadataTag) {
            return metadataUpdate[metadataTag] as? [String] ?? []
        }
        
        return viewModel?.metadataCurrent?[metadataTag] as? [String] ?? []
    }
    
    private func updateKeywords(_ update: ([String]) -> [String]) {
        if pendingKeywordsUpdate == nil {
            if metadataUpdate.keys.contains(metadataTag) {
                pendingKeywordsUpdate = metadataUpdate[metadataTag] as? [String] ?? []
            } else {
                pendingKeywordsUpdate =
                viewModel?.metadataCurrent?[metadataTag] as? [String] ?? []
            }
        }
        
        pendingKeywordsUpdate = update(pendingKeywordsUpdate ?? [])
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                // Keyword list
                List {
                    ForEach(keywords, id: \.self) { keyword in
                        Button {
                            
                        } label: {
                            HStack {
                                Text(keyword)
                                    .lineLimit(10)
                                Spacer()
                            }
                            .padding(4)
                            .frame(maxWidth: .infinity)
                        }
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                updateKeywords { keywords in
                                    keywords.filter { $0 != keyword }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    if keywords.isEmpty {
                        Button {
                            
                        } label: {
                            Text(keywordsStandardView ? "No keywords" : "No persons")
                                .padding(4)
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(true)
                        .listRowSeparator(.hidden)
                    }
                    if newKeyword != nil {
                        Button {
                            
                        } label: {
                            HStack {
                                TextField(
                                    keywordsStandardView ? "New keyword" : "New person",
                                    text: Binding(
                                        get: { newKeyword ?? "" },
                                        set: { newKeyword = $0 }
                                    )
                                )
                                .multilineTextAlignment(.leading)
                                .onSubmit {
                                    let keyword = newKeyword!.trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    guard !keyword.isEmpty,
                                          !keywords.contains(keyword) else {
                                        return
                                    }
                                    
                                    updateKeywords { keywords in
                                        keywords + [keyword]
                                    }
                                    
                                    newKeyword = ""
                                }
                            }
                            .padding(4)
                            .frame(maxWidth: .infinity)
                        }
                        .listRowSeparator(.hidden)
                    }
                    HStack {
                        Spacer()
                        Button {
                            newKeyword = ""
                        } label: {
                            if keywordsStandardView {
                                Text("Add a keyword…")
                            } else {
                                Text("Add a person…")
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .overlay {
                    
                }
                .dropDestination(for: String.self) { items, location in
                    guard let droppedKeyword = items.first else {
                        return false
                    }
                    
                    guard !keywords.contains(droppedKeyword) else {
                        return false
                    }
                    
                    updateKeywords { keywords in
                        keywords + [droppedKeyword]
                    }
                    
                    return true
                }
            }
            .padding([.vertical, .leading], 15)
            .padding(.trailing, 7.5)
            .frame(width: 350)
            VStack {
                Picker("", selection: $presetsSingleSelected) {
                    Text("Single values").tag(true)
                    Text("Multivalue").tag(false)
                }
                .pickerStyle(.segmented)
                // Keyword suggestions
                if presetsSingleSelected {
                    List {
                        ForEach(presetsSingle) { preset in
                            Button {
                                updateKeywords { keywords in
                                    keywords + [preset.value]
                                }
                            } label: {
                                HStack {
                                    Text(preset.value)
                                        .lineLimit(10)
                                        .draggable(preset.value)
                                    Spacer()
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity)
                            }
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(preset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        if presetsSingle.isEmpty {
                            Button {
                                
                            } label: {
                                Text(keywordsStandardView ? "No keyword presets" : "No person presets")
                                    .padding(4)
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(true)
                            .listRowSeparator(.hidden)
                        }
                        if newPresetsSingle != nil {
                            Button {
                                
                            } label: {
                                HStack {
                                    TextField(
                                        keywordsStandardView ? "New keyword preset" : "New person preset",
                                        text: Binding(
                                            get: { newPresetsSingle ?? "" },
                                            set: { newPresetsSingle = $0 }
                                        )
                                    )
                                    .multilineTextAlignment(.leading)
                                    .onSubmit {
                                        let preset = newPresetsSingle!
                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        guard !preset.isEmpty,
                                              !presetsSingle.contains(where: { $0.value == preset }) else {
                                            return
                                        }
                                        
                                        modelContext.insert(
                                            KeywordsPresetsSingle(value: preset)
                                        )
                                        
                                        newPresetsSingle = nil
                                    }
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity)
                            }
                            .listRowSeparator(.hidden)
                        }
                        HStack {
                            Spacer()
                            Button {
                                newPresetsSingle = ""
                            } label: {
                                Text("Add a preset…")
                            }
                        }
                        .padding(.top, 10)
                    }
                } else {
                    List {
                        ForEach(presetsMulti) { preset in
                            Button {
                                updateKeywords { _ in
                                    preset.values
                                }
                            } label: {
                                HStack {
                                    Text(preset.values.joined(separator: ", "))
                                        .lineLimit(10)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity)
                            }
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(preset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        if presetsMulti.isEmpty {
                            Button {
                                
                            } label: {
                                Text(keywordsStandardView ? "No keywords presets" : "No persons presets")
                                    .padding(4)
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(true)
                            .listRowSeparator(.hidden)
                        }
                        if newPresetsMulti != nil {
                            Button {
                                
                            } label: {
                                HStack {
                                    TextField(
                                        keywordsStandardView ? "New keywords preset" : "New persons preset",
                                        text: Binding(
                                            get: { newPresetsMulti ?? "" },
                                            set: { newPresetsMulti = $0 }
                                        )
                                    )
                                    .multilineTextAlignment(.leading)
                                    .onSubmit {
                                        let preset = newPresetsMulti!
                                            .split(separator: ",")
                                            .map {
                                                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                                            }
                                            .filter {
                                                !$0.isEmpty
                                            }
                                        
                                        guard !preset.isEmpty,
                                              !presetsMulti.contains(where: { $0.values == preset }) else {
                                            return
                                        }
                                        
                                        modelContext.insert(
                                            KeywordsPresetsMulti(values: preset)
                                        )
                                        
                                        newPresetsMulti = nil
                                    }
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity)
                            }
                            .listRowSeparator(.hidden)
                        }
                        HStack {
                            Spacer()
                            Button {
                                newPresetsMulti = ""
                            } label: {
                                Text("Add a preset…")
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    Button {
                        metadataUpdate[metadataTag] = pendingKeywordsUpdate
                        guard metadataUpdate[metadataTag] as? [String] == pendingKeywordsUpdate else {
                            return
                        }
                        pendingKeywordsUpdate = nil
                        dismiss()
                    } label: {
                        Text(keywordsStandardView ? "Replace Keywords" : "Replace Persons")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .padding([.vertical, .trailing], 15)
            .padding(.leading, 7.5)
            .frame(width: 350)
        }
        .frame(width: 700, height: 423)
    }
}

@Model
final class KeywordsPresetsSingle {
    var value: String
    
    init(value: String) {
        self.value = value
    }
}

@Model
final class KeywordsPresetsMulti {
    var values: [String]
    
    init(values: [String]) {
        self.values = values
    }
}

#Preview {
    @Previewable @State var viewModel = MetadataViewModel()
    @Previewable @State var metadataUpdate: [MetadataTag: Any?] = [:]
    @Previewable let metadataTag: MetadataTag = .iptcKeywords
    
    EditSheetKeywordsView(keywordsStandardView: true, viewModel: viewModel, metadataUpdate: $metadataUpdate, metadataTag: metadataTag)
        .modelContainer(
            for: [
                KeywordsPresetsSingle.self,
                KeywordsPresetsMulti.self
            ]
        )
}
