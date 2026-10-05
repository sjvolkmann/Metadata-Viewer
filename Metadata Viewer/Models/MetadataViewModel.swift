//
//  MetadataViewModel.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 24.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import Foundation
import SwiftUI

@Observable
final class MetadataViewModel {
    var filePath: URL? {
        didSet {
            filePathChanged()
        }
    }
    
    var metadataCurrent: [MetadataTag: Any]?
    
    private var metadataLoadTask: Task<Void, Never>?
    
    deinit {
        metadataLoadTask?.cancel()
    }
    
    private func filePathChanged() {
        metadataLoadTask?.cancel()
        
        guard let filePath else {
            metadataCurrent = nil
            return
        }
        
        metadataLoadTask = Task { [weak self] in
            do {
                let metadata = try await MetadataService.read(
                    filePath: filePath,
                    tags: metadataTagsAvailable
                )
                
                guard !Task.isCancelled,
                      self?.filePath == filePath
                else {
                    return
                }
                
                self?.metadataCurrent = metadata
                
            } catch {
                guard !Task.isCancelled,
                      self?.filePath == filePath
                else {
                    return
                }
                
                self?.metadataCurrent = [:]
            }
        }
    }
}

let metadataTagsAvailable: [MetadataTag] = [
    .xmpdcCoverage,
    .xmpPhotoshopDateCreated,
    .iptcDateCreated,
    .exifIFDDateTimeOriginal,
    .xmpExifDateTimeDigitized,
    .xmpXmpModifyDate,
    
    .xmpdcTitle,
    .iptcObjectname,
    
    .xmpdcDescription,
    .ifd0ImageDescription,
    .iptcCaptionAbstract,
    
    .xmpdcIdentifier,
    .xmpdcCreator,
    .xmpdcSource,
    
    .xmpdcRights,
    .ifd0Copyright,
    .iptcCopyrightNotice,
    
    .xmpIptcExtPersonInImage,
    
    .xmpdcSubject,
    .iptcKeywords,
    
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
    .xmpIptcExtLocationCreatedLocationName,
    
    .gpsLatitude,
    .gpsLatitudeRef,
    .gpsLongitude,
    .gpsLongitudeRef,
    .gpsSpeed,
    .gpsSpeedRef,
    .gpsProcessingMethod,
    .gpsMapDatum,
    
    .raw
]

enum ReadingWritingStatus: String, Identifiable {
    var id: String { rawValue }
    
    case ready = "Ready"
    case scheduled = "Scheduled"
    case building = "Building"
    case finished = "Finished"
    case cancelled = "Cancelled"
    case failed = "Failed"
}
