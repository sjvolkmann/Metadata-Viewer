//
//  MetadataService.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 19.09.2026.
//

import SwiftUI

struct MetadataService {
    func writeMetadata(
        filePath: String,
        
        // Dates
        dateCreated: String,
        dateCreatedAccurate: Date?,
        dateDigitized: Date?,
        
        // Descriptions
        title: String,
        description: String,
        identifier: String,
        creator: String,
        source: String,
        isPublicDomain: Bool,
        persons: String,
        keywords: String,
        keepExistingKeywords: Bool,
        
        // Location
        locationSublocation: String,
        locationCity: String,
        locationProvince: String,
        locationCountryName: String,
        locationCountryCode: String,
        locationLocationName: String,
        locationLatitude: String,
        locationLongitude: String
    ) throws {
        let year = Calendar.current.component(.year, from: Date())
        @AppStorage("copyrightString") var copyrightString: String = "Copyright © \(year) Killarnee. All rights reserved."
        @AppStorage("exiftoolBinary") var exiftoolBinary: String = "/opt/homebrew/bin/exiftool"
        
        // File exists and is an image
        let allowedExtensions = ["png", "jpg", "jpeg", "tif", "tiff"]
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath),
              allowedExtensions.contains(url.pathExtension.lowercased()) else {
            print("not writable")
            throw NSError(domain: "ExifTool", code: Int(-1))
        }
        
        // Keep filesystem metadata
        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
        let creationDate = attributes[.creationDate] as? Date
        let modificationDate = attributes[.modificationDate] as? Date
        
        let process = Process()
        let errorPipe = Pipe()
        let outputPipe = Pipe()
        var arguments: [String] = [exiftoolBinary, "-overwrite_original"]
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.standardError = errorPipe
        process.standardOutput = outputPipe
        
        // Add arguments for exiftool
        // Dates
        if !dateCreated.isEmpty {
            arguments.append("-XMP-dc:Coverage=\(dateCreated)")
        }
        
        if let dateCreatedAccurate {
            arguments.append("-XMP-photoshop:DateCreated=\(dateCreatedAccurate)")
            arguments.append("-IPTC:DateCreated=\(dateCreatedAccurate)")
            arguments.append("-ExifIFD:DateTimeOriginal=\(dateCreatedAccurate)")
        }
        
        if let dateDigitized {
            arguments.append("-XMP-exif:DateTimeDigitized=\(dateDigitized)")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        arguments.append("-XMP-xmp:ModifyDate=\(formatter.string(from: Date()))")
        
        // Descriptions
        if !title.isEmpty {
            arguments.append("-XMP-dc:Title=\(title)")
            arguments.append("-IPTC:ObjectName=\(title)")
        }

        if !description.isEmpty {
            arguments.append("-XMP-dc:Description=\(description)")
            arguments.append("-IFD0:ImageDescription=\(description)")
            arguments.append("-IPTC:Caption-Abstract=\(description)")
        }

        if !identifier.isEmpty {
            arguments.append("-XMP-dc:Identifier=\(identifier)")
        }

        if !creator.isEmpty {
            arguments.append("-XMP-dc:Creator=\(creator)")
        }

        if !source.isEmpty {
            arguments.append("-XMP-dc:Source=\(source)")
        }
        
        if isPublicDomain {
            arguments.append("-XMP-dc:Rights=Public domain")
            arguments.append("-IFD0:Copyright=Public domain")
            arguments.append("-IPTC:CopyrightNotice=Public domain")
        } else {
            arguments.append("-XMP-dc:Rights=\(copyrightString)")
            arguments.append("-IFD0:Copyright=\(copyrightString)")
            arguments.append("-IPTC:CopyrightNotice=\(copyrightString)")
        }
        
        if !persons.isEmpty {
            let personList = persons.split(separator: ",")

            for person in personList {
                let person = String(person).trimmingCharacters(in: .whitespaces)

                arguments.append("-XMP-iptcExt:PersonInImage=\(person)")
            }
        }
        
        // Keep existing keywords
        let keepExistingKeywordsProcess = Process()
        let keepExistingKeywordsPipe = Pipe()

        keepExistingKeywordsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        keepExistingKeywordsProcess.arguments = [
            exiftoolBinary,
            "-s3",
            "-IPTC:Keywords",
            filePath
        ]
        keepExistingKeywordsProcess.standardOutput = keepExistingKeywordsPipe

        try keepExistingKeywordsProcess.run()
        keepExistingKeywordsProcess.waitUntilExit()

        let keepExistingKeywordsData = keepExistingKeywordsPipe.fileHandleForReading.readDataToEndOfFile()
        let keepExistingKeywordsOutput = String(
            data: keepExistingKeywordsData,
            encoding: .utf8
        ) ?? ""

        if !keepExistingKeywordsOutput.isEmpty {
            let keepExistingKeywordsList = keepExistingKeywordsOutput
                .components(separatedBy: .newlines)
                .flatMap { $0.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if keepExistingKeywords {
                for keepExistingKeyword in keepExistingKeywordsList {
                    arguments.append("-XMP-dc:Subject=\(keepExistingKeyword)")
                    arguments.append("-IPTC:Keywords=\(keepExistingKeyword)")
                }
            } else {
                arguments.append("-XMP-dc:Subject=")
                arguments.append("-IPTC:Keywords=")
            }
        }
        
        // Write new keywords
        if !keywords.isEmpty {
            let keywordList = keywords.split(separator: ",")

            for keyword in keywordList {
                let keyword = String(keyword).trimmingCharacters(in: .whitespaces)

                arguments.append("-XMP-dc:Subject=\(keyword)")
                arguments.append("-IPTC:Keywords=\(keyword)")
            }
        }
        
        // Location
        if !locationSublocation.isEmpty {
            arguments.append("-XMP-iptcExt:LocationCreatedSublocation=\(locationSublocation)")
        }

        if !locationCity.isEmpty {
            arguments.append("-XMP-iptcExt:LocationCreatedCity=\(locationCity)")
        }

        if !locationProvince.isEmpty {
            arguments.append("-XMP-iptcExt:LocationCreatedProvinceState=\(locationProvince)")
            arguments.append("-XMP-photoshop:State=\(locationProvince)")
            arguments.append("-IPTC:Province-State=\(locationProvince)")
        }

        if !locationCountryName.isEmpty {
            arguments.append("-XMP-iptcExt:LocationCreatedCountryName=\(locationCountryName)")
            arguments.append("-XMP-photoshop:Country=\(locationCountryName)")
            arguments.append("-IPTC:Country-PrimaryLocationName=\(locationCountryName)")
        }

        if !locationCountryCode.isEmpty {
            arguments.append("-XMP-iptcExt:LocationCreatedCountryCode=\(locationCountryCode)")
        }

        arguments.append("-XMP-iptcExt:LocationCreatedWorldRegion=Europe")

        if !locationLocationName.isEmpty {
            arguments.append("-XMP-iptcExt:LocationCreatedLocationName=\(locationLocationName)")
        }

        if !locationLatitude.isEmpty && !locationLongitude.isEmpty {
            arguments.append("-GPS:GPSLatitude=\(locationLatitude)")
            arguments.append("-GPS:GPSLatitudeRef=\(locationLatitude.prefix(1))")
            
            arguments.append("-GPS:GPSLongitude=\(locationLongitude)")
            arguments.append("-GPS:GPSLongitudeRef=\(locationLongitude.prefix(1))")
            
            arguments.append("-GPS:GPSSpeed=0")
            arguments.append("-GPS:GPSSpeedRef=K")
            
            arguments.append("-GPS:GPSProcessingMethod=MANUAL")
            arguments.append("-GPS:GPSMapDatum=WGS-84")
        }
        
        // Run exiftool
        arguments.append(filePath)
        process.arguments = arguments
        
        try process.run()
        process.waitUntilExit()
        
        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        
        let errorOutput = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        
        // Restore filesystem metadata
        var restoredAttributes: [FileAttributeKey: Any] = [:]
        
        if let creationDate {
            restoredAttributes[.creationDate] = creationDate
        }
        
        if let modificationDate {
            restoredAttributes[.modificationDate] = modificationDate
        }
        
        try FileManager.default.setAttributes(
            restoredAttributes,
            ofItemAtPath: filePath
        )
        
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "ExifTool",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errorOutput]
            )
        }
    }
}
