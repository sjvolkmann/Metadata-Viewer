//
//  HistoryEntry.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 25.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class HistoryEntry {
    var id: UUID
    var filePath: URL
    var versionDateTime: Date
    
    var versionPrevious: [MetadataTag: Any] {
        Self.decodePrevious(versionPreviousData)
    }
    
    var versionUpdate: [MetadataTag: Any?] {
        Self.decodeUpdate(versionUpdateData)
    }
    
    var versionPreviousData: Data
    var versionUpdateData: Data
    
    init(
        filePath: URL,
        versionPrevious: [MetadataTag: Any],
        versionUpdate: [MetadataTag: Any?]
    ) {
        self.id = UUID()
        self.filePath = filePath
        self.versionDateTime = .now
        //self.versionPrevious = versionPrevious
        //self.versionUpdate = versionUpdate
        
        self.versionPreviousData = try! NSKeyedArchiver.archivedData(
            withRootObject: Dictionary(
                uniqueKeysWithValues: versionPrevious.map {
                    ($0.key.rawValue, $0.value)
                }
            ),
            requiringSecureCoding: false
        )
        
        self.versionUpdateData = try! NSKeyedArchiver.archivedData(
            withRootObject: Dictionary(
                uniqueKeysWithValues: versionUpdate.map { key, value in
                    (key.rawValue, value ?? NSNull())
                }
            ),
            requiringSecureCoding: false
        )
    }
    
    private static func decodePrevious(
        _ data: Data
    ) -> [MetadataTag: Any] {
        guard let object = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [
                NSDictionary.self,
                NSString.self,
                NSNumber.self,
                NSDate.self,
                NSTimeZone.self,
                NSArray.self,
                NSNull.self
            ],
            from: data
        ),
        let dictionary = object as? [String: Any]
        else {
            return [:]
        }
        
        return Dictionary(
            uniqueKeysWithValues: dictionary.compactMap { key, value in
                guard let tag = MetadataTag(rawValue: key) else {
                    return nil
                }
                
                return (tag, value)
            }
        )
    }
    
    private static func decodeUpdate(
        _ data: Data
    ) -> [MetadataTag: Any?] {
        guard let object = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [
                NSDictionary.self,
                NSString.self,
                NSNumber.self,
                NSDate.self,
                NSTimeZone.self,
                NSArray.self,
                NSNull.self
            ],
            from: data
        ),
        let dictionary = object as? [String: Any]
        else {
            return [:]
        }
        
        return Dictionary(
            uniqueKeysWithValues: dictionary.compactMap { key, value in
                guard let tag = MetadataTag(rawValue: key) else {
                    return nil
                }
                
                if value is NSNull {
                    return (tag, nil)
                }
                
                return (tag, value)
            }
        )
    }
}
