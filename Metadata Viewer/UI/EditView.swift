//
//  EditView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 26.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftUI

struct EditView: View {
    let viewModel: MetadataViewModel?
    @Binding var metadataUpdate: [MetadataTag: Any?]
    
    let metadataGroups: [MetadataGroup: [MetadataTag]] = [
        .descriptions: [
            .xmpdcTitle,
            .iptcObjectname,
            .xmpdcDescription,
            .ifd0ImageDescription,
            .iptcCaptionAbstract
        ],
        
        .dates: [
            .xmpdcCoverage,
            .xmpPhotoshopDateCreated,
            .iptcDateCreated,
            .exifIFDDateTimeOriginal,
            .xmpExifDateTimeDigitized,
            .xmpXmpModifyDate
        ],
        
        .keywords: [
            .xmpdcSubject,
            .iptcKeywords
        ],
        
        .people: [
            .xmpIptcExtPersonInImage
        ],
        
        .location: [
            .xmpIptcExtLocationCreatedSublocation,
            .xmpIptcExtLocationCreatedCity,
            .xmpIptcExtLocationCreatedProvinceState,
            .xmpPhotoshopState,
            .iptcProvinceState,
            .xmpIptcExtLocationCreatedCountryName,
            .xmpPhotoshopCountry,
            .iptcCountryPrimaryLocationName,
            .xmpIptcExtLocationCreatedCountryCode,
            .xmpIptcExtLocationCreatedWorldRegion,
            .xmpIptcExtLocationCreatedLocationName
        ],
        
        .gps: [
            .gpsLatitude,
            .gpsLatitudeRef,
            .gpsLongitude,
            .gpsLongitudeRef,
            .gpsSpeed,
            .gpsSpeedRef,
            .gpsProcessingMethod,
            .gpsMapDatum
        ],
        
        .creator: [
            .xmpdcCreator,
            .xmpdcSource,
            .xmpdcIdentifier,
            .xmpdcRights,
            .ifd0Copyright,
            .iptcCopyrightNotice
        ]
    ]
    
    enum MetadataGroup: String, Identifiable, CaseIterable, Codable {
        var id: String { rawValue }
        
        case descriptions = "Descriptions"
        case dates = "Dates"
        case keywords = "Keywords"
        case people = "People"
        case location = "Location"
        case gps = "GPS"
        case creator = "Creator"
    }
    
    @AppStorage("openMetadataGroups") private var openMetadataGroupsData: Data = Data()
    
    private var openMetadataGroups: Set<MetadataGroup> {
        get {
            guard let groups = try? JSONDecoder().decode(
                Set<MetadataGroup>.self,
                from: openMetadataGroupsData
            ) else {
                return []
            }
            
            return groups
        }
        set {
            openMetadataGroupsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    @State private var isShowingMapSheet = false
    
    var body: some View {
        ScrollView {
            if viewModel?.metadataCurrent?.isEmpty ?? true {
                Group {
                    Spacer()
                        .frame(height: 240)
                    Text("Select file to show metadata")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(MetadataGroup.allCases) { metadataGroup in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: {
                                let groups = (try? JSONDecoder().decode(
                                    Set<MetadataGroup>.self,
                                    from: openMetadataGroupsData
                                )) ?? []
                                
                                return groups.contains(metadataGroup)
                            },
                            set: { isExpanded in
                                var groups = (try? JSONDecoder().decode(
                                    Set<MetadataGroup>.self,
                                    from: openMetadataGroupsData
                                )) ?? []
                                
                                if isExpanded {
                                    groups.insert(metadataGroup)
                                } else {
                                    groups.remove(metadataGroup)
                                }
                                
                                openMetadataGroupsData =
                                (try? JSONEncoder().encode(groups)) ?? Data()
                            }
                        )
                    ) {
                        ForEach(metadataGroups[metadataGroup] ?? []) { metadataTag in
                            EditRowsView(viewModel: viewModel, metadataUpdate: $metadataUpdate, metadataTag: metadataTag)
                                .frame(maxWidth: 800)
                        }
                        if metadataGroup == .location || metadataGroup == .gps {
                            HStack {
                                Button(action: {
                                    isShowingMapSheet.toggle()
                                }) {
                                    Text("Show Maps")
                                }
                                .frame(width: 260, alignment: .trailing)
                                .sheet(isPresented: $isShowingMapSheet) {
                                    EditSheetGeodataView()
                                }
                                Spacer()
                            }
                            .frame(maxWidth: 800)
                        }
                    } label: {
                        Text(metadataGroup.rawValue)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = MetadataViewModel()
    @Previewable @State var metadataUpdate: [MetadataTag: Any?] = [:]
    
    EditView(viewModel: viewModel, metadataUpdate: $metadataUpdate)
        .frame(width: 800, height: 523)
}
