//
//  EditRowsView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 27.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import SwiftUI

struct EditRowsView: View {
    let viewModel: MetadataViewModel?
    @Binding var metadataUpdate: [MetadataTag: Any?]
    let metadataTag: MetadataTag
    
    private func metadataString(_ value: Any) -> String {
        if let values = value as? [String] {
            return values.joined(separator: ", ")
        }
        
        return String(describing: value)
    }
    
    private func metadataValue(_ string: String, for tag: MetadataTag) -> Any {
        if tag == .xmpIptcExtPersonInImage ||
            tag == .xmpdcSubject ||
            tag == .iptcKeywords {
            return string
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        return string
    }
    
    private func ensureDateExists(for metadataTag: MetadataTag) -> Date {
        if let date = metadataUpdate[metadataTag] as? Date {
            return date
        }
        
        if let date = viewModel!.metadataCurrent![metadataTag] as? Date {
            return date
        }
        
        let date = Date()
        metadataUpdate[metadataTag] = date
        return date
    }
    
    private func validDouble(
        _ string: String,
        for metadataTag: MetadataTag
    ) -> Double? {
        guard let value = Double(string) else {
            return nil
        }
        
        switch metadataTag {
        case .gpsLatitude:
            guard (-90...90).contains(value) else {
                return nil
            }
            
        case .gpsLongitude:
            guard (-180...180).contains(value) else {
                return nil
            }
            
        case .gpsSpeed:
            guard value >= 0 else {
                return nil
            }
            
        default:
            return nil
        }
        
        return value
    }
    
    private func doubleString(_ value: Double) -> String {
        String(format: "%g", value)
    }
    
    @State private var isShowingKeywordsSheet = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(metadataTag.rawValue)
                .frame(width: 260, alignment: .trailing)
                .foregroundStyle(.secondary)
            if viewModel?.metadataCurrent?.isEmpty ?? true {
                Text("No item")
                    .italic()
                    .allowsHitTesting(false)
                    .padding(.leading, 20)
                Spacer()
            } else {
                if [
                    .xmpPhotoshopDateCreated,
                    .iptcDateCreated,
                    .exifIFDDateTimeOriginal,
                    .xmpExifDateTimeDigitized,
                    .xmpXmpModifyDate
                ].contains(metadataTag) {
                    VStack {
                        HStack {
                            TextField(
                                "Day",
                                text: Binding(
                                    get: {
                                        guard let date = metadataUpdate[metadataTag] as? Date
                                                ?? viewModel!.metadataCurrent![metadataTag] as? Date
                                                else { return "" }
                                        
                                        return Calendar.current.component(.day, from: date).description
                                    },
                                    set: { newValue in
                                        guard let day = Int(newValue) else { return }
                                        
                                        let date = ensureDateExists(for: metadataTag)
                                        
                                        var components = Calendar.current.dateComponents(
                                            [.year, .month, .day, .hour, .minute, .second],
                                            from: date
                                        )
                                        
                                        components.day = day
                                        
                                        if let newDate = Calendar.current.date(from: components) {
                                            metadataUpdate[metadataTag] = newDate
                                        }
                                    }
                                )
                            )
                            .frame(width: 40)
                            
                            Picker(
                                "Month",
                                selection: Binding<Int>(
                                    get: {
                                        guard let date = metadataUpdate[metadataTag] as? Date
                                                ?? viewModel!.metadataCurrent![metadataTag] as? Date
                                                else { return 1 }
                                        
                                        return Calendar.current.component(.month, from: date)
                                    },
                                    set: { newValue in
                                        let date = ensureDateExists(for: metadataTag)
                                        
                                        var components = Calendar.current.dateComponents(
                                            [.year, .month, .day, .hour, .minute, .second],
                                            from: date
                                        )
                                        
                                        components.month = newValue
                                        
                                        if let newDate = Calendar.current.date(from: components) {
                                            metadataUpdate[metadataTag] = newDate
                                        }
                                    }
                                )
                            ) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(Calendar.current.monthSymbols[month - 1])
                                        .tag(month)
                                }
                            }
                            
                            TextField(
                                "Year",
                                text: Binding(
                                    get: {
                                        guard let date = metadataUpdate[metadataTag] as? Date
                                                ?? viewModel!.metadataCurrent![metadataTag] as? Date
                                                else { return "" }
                                        
                                        return Calendar.current.component(.year, from: date).description
                                    },
                                    set: { newValue in
                                        guard let year = Int(newValue) else { return }
                                        
                                        let date = ensureDateExists(for: metadataTag)
                                        
                                        var components = Calendar.current.dateComponents(
                                            [.year, .month, .day, .hour, .minute, .second],
                                            from: date
                                        )
                                        
                                        components.year = year
                                        
                                        if let newDate = Calendar.current.date(from: components) {
                                            metadataUpdate[metadataTag] = newDate
                                        }
                                    }
                                )
                            )
                            .frame(width: 60)
                            
                            TextField(
                                "Hour",
                                text: Binding(
                                    get: {
                                        guard let date = metadataUpdate[metadataTag] as? Date
                                                ?? viewModel!.metadataCurrent![metadataTag] as? Date
                                                else { return "" }
                                        
                                        return Calendar.current.component(.hour, from: date).description
                                    },
                                    set: { newValue in
                                        guard let hour = Int(newValue) else { return }
                                        
                                        let date = ensureDateExists(for: metadataTag)
                                        
                                        var components = Calendar.current.dateComponents(
                                            [.year, .month, .day, .hour, .minute, .second],
                                            from: date
                                        )
                                        
                                        components.hour = hour
                                        
                                        if let newDate = Calendar.current.date(from: components) {
                                            metadataUpdate[metadataTag] = newDate
                                        }
                                    }
                                )
                            )
                            .frame(width: 40)
                            
                            TextField(
                                "Minute",
                                text: Binding(
                                    get: {
                                        guard let date = metadataUpdate[metadataTag] as? Date
                                                ?? viewModel!.metadataCurrent![metadataTag] as? Date
                                                else { return "" }
                                        
                                        return Calendar.current.component(.minute, from: date).description
                                    },
                                    set: { newValue in
                                        guard let minute = Int(newValue) else { return }
                                        
                                        let date = ensureDateExists(for: metadataTag)
                                        
                                        var components = Calendar.current.dateComponents(
                                            [.year, .month, .day, .hour, .minute, .second],
                                            from: date
                                        )
                                        
                                        components.minute = minute
                                        
                                        if let newDate = Calendar.current.date(from: components) {
                                            metadataUpdate[metadataTag] = newDate
                                        }
                                    }
                                )
                            )
                            .frame(width: 40)
                            
                            TextField(
                                "Second",
                                text: Binding(
                                    get: {
                                        guard let date = metadataUpdate[metadataTag] as? Date
                                                ?? viewModel!.metadataCurrent![metadataTag] as? Date
                                                else { return "" }
                                        
                                        return Calendar.current.component(.second, from: date).description
                                    },
                                    set: { newValue in
                                        guard let second = Int(newValue) else { return }
                                        
                                        let date = ensureDateExists(for: metadataTag)
                                        
                                        var components = Calendar.current.dateComponents(
                                            [.year, .month, .day, .hour, .minute, .second],
                                            from: date
                                        )
                                        
                                        components.second = second
                                        
                                        if let newDate = Calendar.current.date(from: components) {
                                            metadataUpdate[metadataTag] = newDate
                                        }
                                    }
                                )
                            )
                            .frame(width: 40)
                            
                            Picker(
                                "Time Zone",
                                selection: Binding<TimeZone>(
                                    get: {
                                        let timeZoneTag: MetadataTag
                                        
                                        switch metadataTag {
                                        case .xmpPhotoshopDateCreated:
                                            timeZoneTag = .xmpPhotoshopDateCreatedTimeZone
                                        case .iptcDateCreated:
                                            timeZoneTag = .iptcDateCreatedTimeZone
                                        case .exifIFDDateTimeOriginal:
                                            timeZoneTag = .exifIFDDateTimeOriginalTimeZone
                                        case .xmpExifDateTimeDigitized:
                                            timeZoneTag = .xmpExifDateTimeDigitizedTimeZone
                                        case .xmpXmpModifyDate:
                                            timeZoneTag = .xmpXmpModifyDateTimeZone
                                        default:
                                            return TimeZone.current
                                        }
                                        
                                        if let value = metadataUpdate[timeZoneTag] as? TimeZone {
                                            return value
                                        }
                                        
                                        if let value = viewModel!.metadataCurrent![timeZoneTag] as? TimeZone {
                                            return value
                                        }
                                        
                                        return TimeZone.current
                                    },
                                    set: { newValue in
                                        let timeZoneTag: MetadataTag
                                        
                                        switch metadataTag {
                                        case .xmpPhotoshopDateCreated:
                                            timeZoneTag = .xmpPhotoshopDateCreatedTimeZone
                                        case .iptcDateCreated:
                                            timeZoneTag = .iptcDateCreatedTimeZone
                                        case .exifIFDDateTimeOriginal:
                                            timeZoneTag = .exifIFDDateTimeOriginalTimeZone
                                        case .xmpExifDateTimeDigitized:
                                            timeZoneTag = .xmpExifDateTimeDigitizedTimeZone
                                        case .xmpXmpModifyDate:
                                            timeZoneTag = .xmpXmpModifyDateTimeZone
                                        default:
                                            return
                                        }
                                        
                                        metadataUpdate[timeZoneTag] = newValue
                                        _ = ensureDateExists(for: metadataTag)
                                    }
                                )
                            ) {
                                Text("UTC")
                                    .tag(TimeZone(identifier: "UTC")!)
                                
                                if let customTimeZone = {
                                    () -> TimeZone? in
                                    
                                    let timeZoneTag: MetadataTag
                                    
                                    switch metadataTag {
                                    case .xmpPhotoshopDateCreated:
                                        timeZoneTag = .xmpPhotoshopDateCreatedTimeZone
                                    case .iptcDateCreated:
                                        timeZoneTag = .iptcDateCreatedTimeZone
                                    case .exifIFDDateTimeOriginal:
                                        timeZoneTag = .exifIFDDateTimeOriginalTimeZone
                                    case .xmpExifDateTimeDigitized:
                                        timeZoneTag = .xmpExifDateTimeDigitizedTimeZone
                                    case .xmpXmpModifyDate:
                                        timeZoneTag = .xmpXmpModifyDateTimeZone
                                    default:
                                        return nil
                                    }
                                    
                                    return metadataUpdate[timeZoneTag] as? TimeZone
                                        ?? viewModel!.metadataCurrent![timeZoneTag] as? TimeZone
                                }(),
                                   !TimeZone.knownTimeZoneIdentifiers.contains(where: {
                                       TimeZone(identifier: $0) == customTimeZone
                                   }) {

                                    let offset = customTimeZone.secondsFromGMT()
                                    let sign = offset >= 0 ? "+" : "-"
                                    let hours = abs(offset) / 3600
                                    let minutes = abs(offset) % 3600 / 60
                                    
                                    Text("GMT \(sign)\(String(format: "%02d:%02d", hours, minutes))")
                                        .tag(customTimeZone)
                                }
                                
                                Divider()
                                
                                ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { identifier in
                                    if let timeZone = TimeZone(identifier: identifier) {
                                        let offset = timeZone.secondsFromGMT()
                                        let sign = offset >= 0 ? "+" : "-"
                                        let hours = abs(offset) / 3600
                                        let minutes = abs(offset) % 3600 / 60
                                        
                                        Text("\(identifier) \(sign)\(String(format: "%02d:%02d", hours, minutes))")
                                            .tag(timeZone)
                                    }
                                }
                            }
                        }
                        .labelsHidden()
                        if metadataUpdate.keys.contains(metadataTag),
                           let updatedValue = metadataUpdate[metadataTag],
                           updatedValue == nil {
                            HStack {
                                Text("Date, time and timezone deleted")
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.leading, 20)
                                Spacer()
                            }
                        } else if !metadataUpdate.keys.contains(metadataTag),
                                  viewModel!.metadataCurrent![metadataTag] == nil {
                            HStack {
                                Text("Date, time and timezone not set")
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.leading, 20)
                                    .padding(.bottom, 11.25)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Button {
                                    metadataUpdate[metadataTag] = nil
                                    metadataUpdate[metadataTag.timeZoneTag!] = nil
                                } label: {
                                    Text("Delete date, time and timezone")
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 20)
                                Spacer()
                            }
                        }
                    }
                } else if [
                    .gpsLatitude,
                    .gpsLongitude,
                    .gpsSpeed
                ].contains(metadataTag) {
                    ZStack(alignment: .leading) {
                        TextField(
                            "",
                            text: Binding(
                                get: {
                                    if let value = metadataUpdate[metadataTag] as? Double {
                                        return doubleString(value)
                                    }
                                    
                                    if let value = viewModel!.metadataCurrent![metadataTag] as? Double {
                                        return doubleString(value)
                                    }
                                    
                                    return ""
                                },
                                set: { newValue in
                                    if newValue.isEmpty {
                                        if viewModel!.metadataCurrent![metadataTag] != nil {
                                            metadataUpdate[metadataTag] = nil
                                        } else {
                                            metadataUpdate.removeValue(forKey: metadataTag)
                                        }
                                        return
                                    }
                                    
                                    guard let value = validDouble(
                                        newValue,
                                        for: metadataTag
                                    ) else {
                                        return
                                    }
                                    
                                    metadataUpdate[metadataTag] = value
                                }
                            )
                        )
                        if metadataUpdate.keys.contains(metadataTag),
                           let updatedValue = metadataUpdate[metadataTag],
                           updatedValue == nil {
                            Text("Deleted")
                                .italic()
                                .foregroundStyle(.secondary)
                                .allowsHitTesting(false)
                                .padding(.leading, 20)
                        } else if !metadataUpdate.keys.contains(metadataTag),
                                  viewModel!.metadataCurrent![metadataTag] == nil {
                            Text("Not set")
                                .italic()
                                .foregroundStyle(.secondary)
                                .allowsHitTesting(false)
                                .padding(.leading, 20)
                        }
                    }
                } else if [
                    .gpsLatitudeRef,
                    .gpsLongitudeRef,
                    .gpsSpeedRef
                ].contains(metadataTag) {
                    HStack {
                        Picker(
                            "",
                            selection: Binding<String?>(
                                get: {
                                    if let value = metadataUpdate[metadataTag] as? String {
                                        return value
                                    }
                                    
                                    if metadataUpdate.keys.contains(metadataTag) {
                                        return nil
                                    }
                                    
                                    if let value = viewModel!.metadataCurrent![metadataTag] as? String {
                                        return value
                                    }
                                    
                                    return nil
                                },
                                set: { newValue in
                                    if newValue == nil {
                                        if viewModel!.metadataCurrent![metadataTag] == nil {
                                            metadataUpdate.removeValue(forKey: metadataTag)
                                        } else {
                                            metadataUpdate[metadataTag] = nil
                                        }
                                    } else {
                                        metadataUpdate[metadataTag] = newValue
                                    }
                                }
                            )
                        ) {
                            Text("No value set")
                                .tag(nil as String?)
                            Divider()
                            
                            switch metadataTag {
                            case .gpsLatitudeRef:
                                Text("N")
                                    .tag("N" as String?)
                                Text("S")
                                    .tag("S" as String?)
                                
                            case .gpsLongitudeRef:
                                Text("E")
                                    .tag("E" as String?)
                                Text("W")
                                    .tag("W" as String?)
                                
                            case .gpsSpeedRef:
                                Text("K — km/h")
                                    .tag("K" as String?)
                                Text("M — mph")
                                    .tag("M" as String?)
                                Text("N — knots")
                                    .tag("N" as String?)
                                
                            default:
                                EmptyView()
                            }
                        }
                        .labelsHidden()
                        
                        if metadataUpdate.keys.contains(metadataTag),
                           metadataUpdate[metadataTag] == nil,
                           viewModel!.metadataCurrent![metadataTag] != nil {
                            Text("Value deleted")
                                .italic()
                                .foregroundStyle(.secondary)
                                .allowsHitTesting(false)
                                .padding(.leading, 20)
                        }
                        
                        Spacer()
                    }
                } else {
                    VStack {
                        ZStack(alignment: .leading) {
                            TextField(
                                "",
                                text: Binding(
                                    get: {
                                        if metadataUpdate.keys.contains(metadataTag) {
                                            if let updatedValue = metadataUpdate[metadataTag] {
                                                if let value = updatedValue {
                                                    return metadataString(value)
                                                }
                                            }
                                            
                                            return ""
                                        }
                                        
                                        if let value = viewModel!.metadataCurrent![metadataTag] {
                                            return metadataString(value)
                                        }
                                        
                                        return ""
                                    },
                                    set: { newValue in
                                        if newValue.isEmpty {
                                            if viewModel!.metadataCurrent![metadataTag] == nil {
                                                // Nothing exists in the file, so there is nothing to remove.
                                                metadataUpdate.removeValue(forKey: metadataTag)
                                            } else {
                                                // Something exists in the file, so this means "delete it".
                                                metadataUpdate.updateValue(nil, forKey: metadataTag)
                                            }
                                        } else {
                                            let newMetadataValue = metadataValue(
                                                newValue,
                                                for: metadataTag
                                            )
                                            
                                            if let currentValue = viewModel!.metadataCurrent![metadataTag] {
                                                if metadataString(currentValue) == metadataString(newMetadataValue) {
                                                    // The value is unchanged, so don't create an update.
                                                    metadataUpdate.removeValue(forKey: metadataTag)
                                                } else {
                                                    metadataUpdate[metadataTag] = newMetadataValue
                                                }
                                            } else {
                                                // There was no original value, so this is a real addition.
                                                metadataUpdate[metadataTag] = newMetadataValue
                                            }
                                        }
                                    }
                                ),
                                axis: .vertical)
                            if metadataUpdate.keys.contains(metadataTag),
                               let updatedValue = metadataUpdate[metadataTag],
                               updatedValue == nil {
                                Text("Deleted")
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.leading, 20)
                            } else if !metadataUpdate.keys.contains(metadataTag),
                                      viewModel!.metadataCurrent![metadataTag] == nil {
                                Text("Not set")
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.leading, 20)
                            }
                        }
                        if metadataTag == .xmpIptcExtPersonInImage ||
                            metadataTag == .xmpdcSubject ||
                            metadataTag == .iptcKeywords {
                            var keywordsStandardView = true
                            HStack {
                                Button(action: {
                                    if metadataTag == .xmpdcSubject ||
                                        metadataTag == .iptcKeywords {
                                        keywordsStandardView = true
                                    } else {
                                        keywordsStandardView = false
                                    }
                                    isShowingKeywordsSheet.toggle()
                                }) {
                                    if metadataTag == .xmpIptcExtPersonInImage {
                                        Text("Show Persons")
                                    } else {
                                        Text("Show Keywords")
                                    }
                                }
                                .padding(.leading, 20)
                                .sheet(isPresented: $isShowingKeywordsSheet) {
                                    EditSheetKeywordsView(keywordsStandardView: keywordsStandardView, viewModel: viewModel, metadataUpdate: $metadataUpdate, metadataTag: metadataTag)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: 800)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 800)
    }
}

#Preview {
    @Previewable @State var viewModel = MetadataViewModel()
    @Previewable @State var metadataUpdate: [MetadataTag: Any?] = [:]
    @Previewable var metadataTag: MetadataTag = .exifIFDDateTimeOriginal
    
    EditRowsView(viewModel: viewModel, metadataUpdate: $metadataUpdate, metadataTag: .exifIFDDateTimeOriginal)
}
