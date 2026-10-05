//
//  MetadataService.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 19.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftUI

struct MetadataService {
    @AppStorage("exiftoolBinary") private static var exiftoolBinary: String = "/opt/homebrew/bin/exiftool"
    
    static func read(filePath: URL) async throws -> [String: Any] {
        let fileManager = FileManager.default
        
        // MARK: Validate input file
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(
            atPath: filePath.path,
            isDirectory: &isDirectory
        ),
        !isDirectory.boolValue
        //fileManager.isReadableFile(atPath: filePath.path) // App in sandbox so always false, file though always readable as exiftool not in sandbox
        else {
            throw MetadataServiceError.fileNotReadable
        }
        
        // MARK: Validate ExifTool
        
        guard fileManager.fileExists(atPath: exiftoolBinary),
              fileManager.isExecutableFile(atPath: exiftoolBinary)
        else {
            throw MetadataServiceError.exiftoolNotFound
        }
        
        let exiftoolURL = URL(fileURLWithPath: exiftoolBinary)
        
        // MARK: Temporary files
        
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(
                "MetadataService-\(UUID().uuidString)",
                isDirectory: true
            )
        
        do {
            try fileManager.createDirectory(
                at: temporaryDirectory,
                withIntermediateDirectories: false
            )
        } catch {
            throw NSError(
                domain: "MetadataService",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not create a temporary directory.",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        defer {
            try? fileManager.removeItem(at: temporaryDirectory)
        }
        
        let outputURL = temporaryDirectory
            .appendingPathComponent("stdout.json")
        
        let errorURL = temporaryDirectory
            .appendingPathComponent("stderr.txt")
        
        guard fileManager.createFile(
            atPath: outputURL.path,
            contents: nil
        ) else {
            throw NSError(
                domain: "MetadataService",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not create the ExifTool output file."
                ]
            )
        }
        
        guard fileManager.createFile(
            atPath: errorURL.path,
            contents: nil
        ) else {
            throw NSError(
                domain: "MetadataService",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not create the ExifTool error file."
                ]
            )
        }
        
        // MARK: Open temporary files
        
        let outputHandle: FileHandle
        let errorHandle: FileHandle
        
        do {
            outputHandle = try FileHandle(forWritingTo: outputURL)
            errorHandle = try FileHandle(forWritingTo: errorURL)
        } catch {
            throw NSError(
                domain: "MetadataService",
                code: 4,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not open temporary files for ExifTool.",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        defer {
            try? outputHandle.close()
            try? errorHandle.close()
        }
        
        // MARK: Configure ExifTool process
        
        let process = Process()
        
        process.executableURL = exiftoolURL
        
        process.arguments = [
            "-json",
            "-G1",
            "-a",
            "-u",
            "-n",
            filePath.path
        ]
        
        // Never allow ExifTool to inherit the app's standard input.
        process.standardInput = FileHandle.nullDevice
        
        process.standardOutput = outputHandle
        process.standardError = errorHandle
        
        // MARK: Start and asynchronously wait for ExifTool
        
        let terminationStatus: Int32
        
        do {
            terminationStatus = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Int32, Error>) in
                
                process.terminationHandler = { terminatedProcess in
                    continuation.resume(
                        returning: terminatedProcess.terminationStatus
                    )
                }
                
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            throw NSError(
                domain: "ExifTool",
                code: 5,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not start ExifTool.",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        // MARK: Read ExifTool error output
        
        let errorData: Data
        
        do {
            errorData = try Data(contentsOf: errorURL)
        } catch {
            throw NSError(
                domain: "ExifTool",
                code: 6,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not read ExifTool's error output.",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        guard terminationStatus == 0 else {
            let errorMessage = String(
                data: errorData,
                encoding: .utf8
            )?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let message: String
            
            if let errorMessage, !errorMessage.isEmpty {
                message = "ExifTool terminated with exit code \(terminationStatus): \(errorMessage)"
            } else {
                message = "ExifTool terminated with exit code \(terminationStatus)."
            }
            
            throw NSError(
                domain: "ExifTool",
                code: Int(terminationStatus),
                userInfo: [
                    NSLocalizedDescriptionKey: message
                ]
            )
        }
        
        // MARK: Read JSON output
        
        let outputData: Data
        
        do {
            outputData = try Data(contentsOf: outputURL)
        } catch {
            throw NSError(
                domain: "ExifTool",
                code: 7,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not read ExifTool's metadata output.",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        guard !outputData.isEmpty else {
            throw NSError(
                domain: "ExifTool",
                code: 8,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "ExifTool returned no metadata."
                ]
            )
        }
        
        // MARK: Parse JSON
        
        let json: Any
        
        do {
            json = try JSONSerialization.jsonObject(
                with: outputData,
                options: []
            )
        } catch {
            throw NSError(
                domain: "ExifTool",
                code: 9,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "ExifTool returned invalid JSON.",
                    NSUnderlyingErrorKey: error
                ]
            )
        }
        
        guard let metadataArray = json as? [[String: Any]],
              let metadata = metadataArray.first
        else {
            throw NSError(
                domain: "ExifTool",
                code: 10,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "ExifTool returned an unexpected JSON structure."
                ]
            )
        }
        
        return metadata
    }
    
    static func read(
        filePath: URL,
        tags: [MetadataTag]
    ) async throws -> [MetadataTag: Any] {
        let metadataDictionary: [String: Any]
        
        do {
            metadataDictionary = try await Self.read(filePath: filePath)
        } catch {
            throw error
        }
        
        var metadata: [MetadataTag: Any] = [:]
        
        let dateTags: Set<MetadataTag> = [
            .xmpPhotoshopDateCreated,
            .iptcDateCreated,
            .exifIFDDateTimeOriginal,
            .xmpExifDateTimeDigitized,
            .xmpXmpModifyDate
        ]
        
        let timeZoneTags: Set<MetadataTag> = [
            .xmpPhotoshopDateCreatedTimeZone,
            .iptcDateCreatedTimeZone,
            .exifIFDDateTimeOriginalTimeZone,
            .xmpExifDateTimeDigitizedTimeZone,
            .xmpXmpModifyDateTimeZone
        ]
        
        for tag in tags {
            if tag == .raw {
                metadata[.raw] = metadataDictionary
                
            } else if dateTags.contains(tag) {
                guard let value = metadataDictionary[tag.rawValue] as? String else {
                    continue
                }
                
                let timeZone: TimeZone
                
                if let timeZoneTag = tag.timeZoneTag,
                   let timeZoneValue = metadataDictionary[timeZoneTag.rawValue] as? String,
                   let parsedTimeZone = parseTimeZone(timeZoneValue) {
                    
                    timeZone = parsedTimeZone
                    
                } else if let embeddedTimeZone = parseEmbeddedTimeZone(value) {
                    
                    timeZone = embeddedTimeZone
                    
                } else {
                    
                    timeZone = TimeZone(secondsFromGMT: 0)!
                }
                
                guard let date = parseDate(
                    value,
                    timeZone: timeZone
                ) else {
                    continue
                }
                
                metadata[tag] = date
                
                if let timeZoneTag = tag.timeZoneTag {
                    metadata[timeZoneTag] = timeZone
                }
                
            } else if timeZoneTags.contains(tag) {
                if let value = metadataDictionary[tag.rawValue] as? String,
                   let timeZone = parseTimeZone(value) {
                    
                    metadata[tag] = timeZone
                    
                } else {
                    metadata[tag] = TimeZone(secondsFromGMT: 0)!
                }
                
            } else if let value = metadataDictionary[tag.rawValue] {
                metadata[tag] = value
            }
        }
        
        return metadata
    }
    
    private static func parseDate(
        _ string: String,
        timeZone: TimeZone
    ) -> Date? {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        
        // Date with an explicit timezone offset, e.g.
        // 1879:12:31 23:06:32+00:00
        // 2026:09:20 07:09:12+02:00
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ssXXXXX"
        
        if let date = formatter.date(from: value) {
            return date
        }
        
        // Date without an embedded timezone.
        // Uses the already determined timezone.
        formatter.timeZone = timeZone
        
        for format in [
            "yyyy:MM:dd HH:mm:ss",
            "yyyy:MM:dd"
        ] {
            formatter.dateFormat = format
            
            if let date = formatter.date(from: value) {
                return date
            }
        }
        
        return nil
    }
    
    private static func parseEmbeddedTimeZone(_ string: String) -> TimeZone? {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // ISO-style UTC suffix.
        if value.hasSuffix("Z") {
            return TimeZone(secondsFromGMT: 0)
        }
        
        // Extract an offset at the end of the date:
        // +00:00
        // +02:00
        // -05:00
        // +0100
        let pattern = #"([+-]\d{2}:?\d{2})$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: value,
                  range: NSRange(value.startIndex..., in: value)
              ),
              let range = Range(match.range(at: 1), in: value) else {
            return nil
        }
        
        return parseTimeZone(String(value[range]))
    }
    
    private static func parseTimeZone(_ string: String) -> TimeZone? {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let timeZone = TimeZone(identifier: value) {
            return timeZone
        }
        
        let pattern = #"^([+-])(\d{2}):?(\d{2})$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: value,
                  range: NSRange(value.startIndex..., in: value)
              ),
              let signRange = Range(match.range(at: 1), in: value),
              let hourRange = Range(match.range(at: 2), in: value),
              let minuteRange = Range(match.range(at: 3), in: value),
              let hours = Int(value[hourRange]),
              let minutes = Int(value[minuteRange]) else {
            return nil
        }
        
        let seconds = hours * 3600 + minutes * 60
        let signedSeconds = value[signRange] == "+"
            ? seconds
            : -seconds

        return TimeZone(secondsFromGMT: signedSeconds)
    }
    
    static func write(
        filePath: URL,
        metadata: [MetadataTag: Any?]
    ) async throws {
        let fileManager = FileManager.default
        
        // MARK: Validate input file
        
        //let allowedExtensions = ["png", "jpg", "jpeg", "tif", "tiff"]
        
        //guard filePath.isFileURL,
        //      fileManager.fileExists(atPath: filePath.path),
        //      allowedExtensions.contains(filePath.pathExtension.lowercased())
        //else {
        //    throw MetadataServiceError.fileNotWritable
        //}
        
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(
            atPath: filePath.path,
            isDirectory: &isDirectory
        ),
        !isDirectory.boolValue
        else {
            throw MetadataServiceError.fileNotWritable
        }
        
        //guard fileManager.isWritableFile(atPath: filePath.path) else {
        //    throw MetadataServiceError.fileNotWritable
        //}
        
        guard fileManager.isExecutableFile(atPath: Self.exiftoolBinary) else {
            throw MetadataServiceError.exiftoolNotFound
        }
        
        // MARK: Preserve filesystem metadata
        
        let attributes = try fileManager.attributesOfItem(atPath: filePath.path)
        
        let creationDate = attributes[.creationDate] as? Date
        let modificationDate = attributes[.modificationDate] as? Date
        
        // MARK: Build ExifTool arguments
        
        var arguments: [String] = [
            Self.exiftoolBinary,
            "-overwrite_original_in_place",
            "-XMP-x:XMPToolkit=Killarnee Metadata Viewer"
        ]
        
        // DateFormatter is deliberately configured per metadata timezone.
        // A Date itself has no timezone, so the corresponding timezone tag
        // determines how the local metadata time is represented.
        func timeZone(
            for tag: MetadataTag
        ) -> TimeZone {
            guard let timeZoneTag = tag.timeZoneTag else {
                return TimeZone(secondsFromGMT: 0)!
            }
            
            if let value = metadata[timeZoneTag] as? TimeZone {
                return value
            }
            
            // Keep compatibility with previously stored string values.
            if let value = metadata[timeZoneTag] as? String,
               !value.isEmpty {
                if value.uppercased() == "Z" {
                    return TimeZone(secondsFromGMT: 0)!
                }
                
                let normalized = value.hasPrefix("+") || value.hasPrefix("-")
                ? value
                : "+\(value)"
                
                if normalized.count == 6,
                   let sign = normalized.first,
                   sign == "+" || sign == "-",
                   let hours = Int(normalized.dropFirst().prefix(2)),
                   let minutes = Int(normalized.suffix(2)) {
                    let seconds = (hours * 60 + minutes) * 60
                    
                    return TimeZone(
                        secondsFromGMT: sign == "+"
                        ? seconds
                        : -seconds
                    )!
                }
            }
            
            return TimeZone(secondsFromGMT: 0)!
        }
        
        func timeZoneOffset(
            for timeZone: TimeZone,
            at date: Date
        ) -> String {
            let seconds = timeZone.secondsFromGMT(for: date)
            
            if seconds == 0 {
                return "Z"
            }
            
            let sign = seconds >= 0 ? "+" : "-"
            let absoluteSeconds = abs(seconds)
            
            let hours = absoluteSeconds / 3600
            let minutes = (absoluteSeconds % 3600) / 60
            
            return String(
                format: "%@%02d:%02d",
                sign,
                hours,
                minutes
            )
        }
        
        func formatDate(
            _ date: Date,
            for tag: MetadataTag
        ) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            
            let zone = timeZone(for: tag)
            formatter.timeZone = zone
            
            switch tag {
            case .xmpPhotoshopDateCreated,
                    .xmpExifDateTimeDigitized,
                    .xmpXmpModifyDate:
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
                
            case .exifIFDDateTimeOriginal:
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                
            case .iptcDateCreated:
                formatter.dateFormat = "yyyyMMdd"
                
            default:
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
            }
            
            return formatter.string(from: date)
        }
        
        for (tag, value) in metadata {
            let argument = "-\(tag.rawValue)="
            
            // nil means that the metadata tag should be deleted.
            if value == nil {
                arguments.append(argument)
                continue
            }
            
            guard let value else {
                continue
            }
            
            if let string = value as? String {
                guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continue
                }
                
                arguments.append(argument + string)
                
            } else if let int = value as? Int {
                arguments.append(argument + String(int))
                
            } else if let int8 = value as? Int8 {
                arguments.append(argument + String(int8))
                
            } else if let int16 = value as? Int16 {
                arguments.append(argument + String(int16))
                
            } else if let int32 = value as? Int32 {
                arguments.append(argument + String(int32))
                
            } else if let int64 = value as? Int64 {
                arguments.append(argument + String(int64))
                
            } else if let uint = value as? UInt {
                arguments.append(argument + String(uint))
                
            } else if let uint8 = value as? UInt8 {
                arguments.append(argument + String(uint8))
                
            } else if let uint16 = value as? UInt16 {
                arguments.append(argument + String(uint16))
                
            } else if let uint32 = value as? UInt32 {
                arguments.append(argument + String(uint32))
                
            } else if let uint64 = value as? UInt64 {
                arguments.append(argument + String(uint64))
                
            } else if let double = value as? Double {
                arguments.append(argument + String(double))
                
            } else if let float = value as? Float {
                arguments.append(argument + String(float))
                
            } else if let decimal = value as? Decimal {
                arguments.append(
                    argument + NSDecimalNumber(decimal: decimal).stringValue
                )
                
            } else if let timeZone = value as? TimeZone {
                guard let dateTag = metadata.first(where: {
                    $0.key.timeZoneTag == tag
                })?.key else {
                    // A timezone without a corresponding date tag
                    // is still valid metadata, so use the current date
                    // only for calculating its UTC offset.
                    arguments.append(
                        argument + timeZoneOffset(
                            for: timeZone,
                            at: Date()
                        )
                    )
                    continue
                }
                
                guard let date = metadata[dateTag] as? Date else {
                    arguments.append(
                        argument + timeZoneOffset(
                            for: timeZone,
                            at: Date()
                        )
                    )
                    continue
                }
                
                arguments.append(
                    argument + timeZoneOffset(
                        for: timeZone,
                        at: date
                    )
                )
                
            } else if let date = value as? Date {
                arguments.append(
                    argument + formatDate(date, for: tag)
                )
                
            } else if let values = value as? [String] {
                for value in values {
                    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continue
                    }
                    
                    arguments.append(argument + value)
                }
                
            } else {
                throw NSError(
                    domain: "MetadataService",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Unsupported metadata value for \(tag.rawValue): \(type(of: value))"
                    ]
                )
            }
        }
        
        arguments.append(filePath.path)
        
        // MARK: Temporary output files
        
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(
                "MetadataViewer-\(UUID().uuidString)",
                isDirectory: true
            )
        
        try fileManager.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        
        let outputURL = temporaryDirectory.appendingPathComponent("stdout")
        let errorURL = temporaryDirectory.appendingPathComponent("stderr")
        
        defer {
            try? fileManager.removeItem(at: temporaryDirectory)
        }
        
        fileManager.createFile(atPath: outputURL.path, contents: nil)
        fileManager.createFile(atPath: errorURL.path, contents: nil)
        
        let outputHandle = try FileHandle(forWritingTo: outputURL)
        let errorHandle = try FileHandle(forWritingTo: errorURL)
        
        defer {
            try? outputHandle.close()
            try? errorHandle.close()
        }
        
        // MARK: Run ExifTool asynchronously
        
        let terminationStatus: Int32 = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Int32, Error>) in
            
            let process = Process()
            
            process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
            process.arguments = arguments
            
            process.standardOutput = outputHandle
            process.standardError = errorHandle
            
            process.terminationHandler = { process in
                continuation.resume(
                    returning: process.terminationStatus
                )
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        // Make sure all subprocess output has been written before reading it.
        try outputHandle.synchronize()
        try errorHandle.synchronize()
        
        let outputData = try Data(contentsOf: outputURL)
        let errorData = try Data(contentsOf: errorURL)
        
        let output = String(
            data: outputData,
            encoding: .utf8
        ) ?? ""
        
        let errorOutput = String(
            data: errorData,
            encoding: .utf8
        ) ?? ""
        
        // MARK: Check ExifTool result
        
        guard terminationStatus == 0 else {
            throw NSError(
                domain: "ExifTool",
                code: Int(terminationStatus),
                userInfo: [
                    NSLocalizedDescriptionKey:
                        errorOutput.isEmpty
                            ? "ExifTool failed with exit status \(terminationStatus)."
                            : errorOutput
                ]
            )
        }
        
        // MARK: Restore filesystem metadata
        
        var restoredAttributes: [FileAttributeKey: Any] = [:]
        
        if let creationDate {
            restoredAttributes[.creationDate] = creationDate
        }
        
        if let modificationDate {
            restoredAttributes[.modificationDate] = modificationDate
        }
        
        if !restoredAttributes.isEmpty {
            try fileManager.setAttributes(
                restoredAttributes,
                ofItemAtPath: filePath.path
            )
        }
        
        if !output.isEmpty {
            print("ExifTool output:", output)
        }
    }
}

enum MetadataServiceError: Error {
    case exiftoolNotFound
    
    case fileNotReadable
    case fileNotWritable
}

enum MetadataTag: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    
    case xmpdcCoverage = "XMP-dc:Coverage"
    case xmpPhotoshopDateCreated = "XMP-photoshop:DateCreated"
    case xmpPhotoshopDateCreatedTimeZone = "XMP-photoshop:DateCreated:TimeZone"
    case iptcDateCreated = "IPTC:DateCreated"
    case iptcDateCreatedTimeZone = "IPTC:DateCreated:TimeZone"
    case exifIFDDateTimeOriginal = "ExifIFD:DateTimeOriginal"
    case exifIFDDateTimeOriginalTimeZone = "ExifIFD:DateTimeOriginal:TimeZone"
    case xmpExifDateTimeDigitized = "XMP-exif:DateTimeDigitized"
    case xmpExifDateTimeDigitizedTimeZone = "XMP-exif:DateTimeDigitized:TimeZone"
    case xmpXmpModifyDate = "XMP-xmp:ModifyDate"
    case xmpXmpModifyDateTimeZone = "XMP-xmp:ModifyDate:TimeZone"
    
    case xmpdcTitle = "XMP-dc:Title"
    case iptcObjectname = "IPTC:ObjectName"
    
    case xmpdcDescription = "XMP-dc:Description"
    case ifd0ImageDescription = "IFD0:ImageDescription"
    case iptcCaptionAbstract = "IPTC:Caption-Abstract"
    
    case xmpdcIdentifier = "XMP-dc:Identifier"
    case xmpdcCreator = "XMP-dc:Creator"
    case xmpdcSource = "XMP-dc:Source"
    
    case xmpdcRights = "XMP-dc:Rights"
    case ifd0Copyright = "IFD0:Copyright"
    case iptcCopyrightNotice = "IPTC:CopyrightNotice"
    
    case xmpIptcExtPersonInImage = "XMP-iptcExt:PersonInImage"
    
    case xmpdcSubject = "XMP-dc:Subject"
    case iptcKeywords = "IPTC:Keywords"
    
    case xmpIptcExtLocationCreatedSublocation = "XMP-iptcExt:LocationCreatedSublocation"
    case xmpIptcExtLocationCreatedCity = "XMP-iptcExt:LocationCreatedCity"
    case xmpIptcExtLocationCreatedProvinceState = "XMP-iptcExt:LocationCreatedProvinceState"
    case xmpPhotoshopState = "XMP-photoshop:State"
    case iptcProvinceState = "IPTC:Province-State"
    case xmpIptcExtLocationCreatedCountryName = "XMP-iptcExt:LocationCreatedCountryName"
    case xmpPhotoshopCountry = "XMP-photoshop:Country"
    case iptcCountryPrimaryLocationName = "IPTC:Country-PrimaryLocationName"
    case xmpIptcExtLocationCreatedCountryCode = "XMP-iptcExt:LocationCreatedCountryCode"
    case xmpIptcExtLocationCreatedWorldRegion = "XMP-iptcExt:LocationCreatedWorldRegion"
    case xmpIptcExtLocationCreatedLocationName = "XMP-iptcExt:LocationCreatedLocationName"
    
    case gpsLatitude = "GPS:GPSLatitude"
    case gpsLatitudeRef = "GPS:GPSLatitudeRef"
    case gpsLongitude = "GPS:GPSLongitude"
    case gpsLongitudeRef = "GPS:GPSLongitudeRef"
    case gpsSpeed = "GPS:GPSSpeed"
    case gpsSpeedRef = "GPS:GPSSpeedRef"
    case gpsProcessingMethod = "GPS:GPSProcessingMethod"
    case gpsMapDatum = "GPS:GPSMapDatum"
    
    case raw = "raw"
}

extension MetadataTag {
    var timeZoneTag: MetadataTag? {
        switch self {
        case .xmpPhotoshopDateCreated:
            .xmpPhotoshopDateCreatedTimeZone
        case .iptcDateCreated:
            .iptcDateCreatedTimeZone
        case .exifIFDDateTimeOriginal:
            .exifIFDDateTimeOriginalTimeZone
        case .xmpExifDateTimeDigitized:
            .xmpExifDateTimeDigitizedTimeZone
        case .xmpXmpModifyDate:
            .xmpXmpModifyDateTimeZone
        default:
            nil
        }
    }
}
