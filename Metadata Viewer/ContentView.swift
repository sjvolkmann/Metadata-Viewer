//
//  ContentView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 18.09.2026.
//

import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var filePath: String = ""
    
    // Dates
    @State private var dateCreated: String = ""
    @State private var dateCreatedAccurateString: String = ""
    @State private var dateCreatedAccurate: Date?
    @State private var dateDigitizedString: String = ""
    @State private var dateDigitized:  Date?
    
    private let currentDate = Date().formatted(
        .dateTime
        .day()
        .month(.wide)
        .year()
    )
    
    // Descriptions
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var identifier: String = ""
    @State private var creator: String = ""
    @State private var source: String = ""
    @State private var isPublicDomain: Bool = false
    @State private var persons: String = ""
    @State private var keywords: String = ""
    @State private var keepExistingKeywords: Bool = true
    
    // Writing location
    @State private var locationSearchText: String = ""
    @State private var coordinates = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.0069, longitude: 8.4037),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var locationSearchResults: [MKMapItem] = []
    
    @State private var locationSublocation: String = ""
    @State private var locationCity: String = ""
    @State private var locationProvince: String = ""
    @State private var locationCountryName: String = ""
    @State private var locationCountryCode: String = ""
    @State private var locationLocationName: String = ""
    @State private var locationLatitude: String = ""
    @State private var locationLongitude: String = ""
    @State private var coordinatePrecision: Double = 4
    @State private var mapCoordinate: CLLocationCoordinate2D?
    @State private var coordinateAccuracyRadius: CLLocationDistance = 0
    
    // Processing
    @State private var showingFilePicker: Bool = false
    @State private var status: String = ""
    
    var body: some View {
        ScrollView {
            VStack {
                Grid {
                    GridRow {
                        Text("File path")
                            .gridColumnAlignment(.trailing)
                        HStack {
                            TextField("", text: $filePath)
                                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                                    filePath = ""
                                    
                                    guard let provider = providers.first else {
                                        return false
                                    }
                                    
                                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                                        guard let url else {
                                            return
                                        }
                                        
                                        DispatchQueue.main.async {
                                            filePath = url.path
                                        }
                                    }
                                    
                                    return true
                                }
                                .onChange(of: filePath) {
                                    // Fill the fields with already existing metadata
                                    if let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil),
                                       let metadata = CGImageSourceCopyMetadataAtIndex(imageSource, 0, nil) {
                                        print(metadata)
                                        
                                        // Dates
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:coverage" as CFString
                                        ) as String? {
                                            dateCreated = value
                                        }
                                        
                                        
                                        // Date Created – XMP
                                        let dateCreatedAccurateValue = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "photoshop:DateCreated" as CFString
                                        ) as String?
                                        
                                        
                                        // Date Created – IPTC
                                        let iptcDateCreatedValue: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyIPTCDictionary,
                                            kCGImagePropertyIPTCDateCreated
                                        ) {
                                            iptcDateCreatedValue = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            iptcDateCreatedValue = nil
                                        }
                                        
                                        
                                        // Time Created – IPTC
                                        let iptcTimeCreatedValue: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyIPTCDictionary,
                                            kCGImagePropertyIPTCTimeCreated
                                        ) {
                                            iptcTimeCreatedValue = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            iptcTimeCreatedValue = nil
                                        }
                                        
                                        
                                        // Date Created – EXIF
                                        let exifDateCreatedValue: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyExifDictionary,
                                            kCGImagePropertyExifDateTimeOriginal
                                        ) {
                                            exifDateCreatedValue = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            exifDateCreatedValue = nil
                                        }
                                        
                                        
                                        // Convert XMP DateCreated
                                        var dateCreatedAccurate1: Date?
                                        
                                        if let value = dateCreatedAccurateValue {
                                            dateCreatedAccurate1 = ISO8601DateFormatter().date(from: value)
                                        }
                                        
                                        
                                        // Convert IPTC DateCreated + TimeCreated
                                        var dateCreatedAccurate2: Date?
                                        
                                        if let dateValue = iptcDateCreatedValue {
                                            let formatter = DateFormatter()
                                            
                                            if let timeValue = iptcTimeCreatedValue {
                                                formatter.dateFormat = "yyyyMMddHHmmss"
                                                dateCreatedAccurate2 = formatter.date(from: dateValue + timeValue)
                                            } else {
                                                formatter.dateFormat = "yyyyMMdd"
                                                dateCreatedAccurate2 = formatter.date(from: dateValue)
                                            }
                                        }
                                        
                                        
                                        // Convert EXIF DateTimeOriginal
                                        var dateCreatedAccurate3: Date?
                                        
                                        if let value = exifDateCreatedValue {
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                                            dateCreatedAccurate3 = formatter.date(from: value)
                                        }
                                        
                                        
                                        // Date Created String
                                        var dateCreatedAccurateValues: [String] = []
                                        
                                        if let value = dateCreatedAccurateValue {
                                            dateCreatedAccurateValues.append(value)
                                        }
                                        
                                        if let dateValue = iptcDateCreatedValue {
                                            if let timeValue = iptcTimeCreatedValue {
                                                dateCreatedAccurateValues.append(dateValue + timeValue)
                                            } else {
                                                dateCreatedAccurateValues.append(dateValue)
                                            }
                                        }
                                        
                                        if let value = exifDateCreatedValue {
                                            dateCreatedAccurateValues.append(value)
                                        }
                                        
                                        if dateCreatedAccurateValues.isEmpty {
                                            dateCreatedAccurateString = "No date set!"
                                            dateCreatedAccurate = nil
                                        } else if dateCreatedAccurateValues.dropFirst().allSatisfy({
                                            $0 == dateCreatedAccurateValues.first
                                        }) {
                                            dateCreatedAccurateString = dateCreatedAccurateValues[0]
                                            
                                            dateCreatedAccurate =
                                            dateCreatedAccurate1 ??
                                            dateCreatedAccurate2 ??
                                            dateCreatedAccurate3
                                        } else {
                                            dateCreatedAccurateString = "Multiple values!"
                                            dateCreatedAccurate = nil
                                        }
                                        
                                        
                                        // Date Digitized – XMP
                                        let dateDigitizedValue = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "exif:DateTimeDigitized" as CFString
                                        ) as String?
                                        
                                        
                                        // Date Digitized – EXIF
                                        let exifDateDigitizedValue: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyExifDictionary,
                                            kCGImagePropertyExifDateTimeDigitized
                                        ) {
                                            exifDateDigitizedValue = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            exifDateDigitizedValue = nil
                                        }
                                        
                                        
                                        // Date Digitized String
                                        var dateDigitizedValues: [String] = []
                                        
                                        if let value = dateDigitizedValue {
                                            dateDigitizedValues.append(value)
                                        }
                                        
                                        if let value = exifDateDigitizedValue,
                                           !dateDigitizedValues.contains(value) {
                                            dateDigitizedValues.append(value)
                                        }
                                        
                                        if dateDigitizedValues.isEmpty {
                                            dateDigitizedString = "No date set!"
                                            dateDigitized = nil
                                        } else if dateDigitizedValues.dropFirst().allSatisfy({
                                            $0 == dateDigitizedValues.first
                                        }) {
                                            dateDigitizedString = dateDigitizedValues[0]
                                            
                                            dateDigitized = ISO8601DateFormatter().date(
                                                from: dateDigitizedValues[0]
                                            )
                                        } else {
                                            dateDigitizedString = "Multiple values!"
                                            dateDigitized = nil
                                        }
                                        
                                        
                                        // Title
                                        let titleValue = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:title" as CFString
                                        ) as String?
                                        
                                        let titleValue2: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyIPTCDictionary,
                                            kCGImagePropertyIPTCObjectName
                                        ) {
                                            titleValue2 = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            titleValue2 = nil
                                        }
                                        
                                        if let titleValue, let titleValue2 {
                                            title = titleValue == titleValue2 ? titleValue : "Multiple values!"
                                        } else if titleValue != nil || titleValue2 != nil {
                                            title = "Multiple values!"
                                        }
                                        
                                        
                                        // Description
                                        let descriptionValue = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:description" as CFString
                                        ) as String?
                                        
                                        let descriptionValue2: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyTIFFDictionary,
                                            kCGImagePropertyTIFFImageDescription
                                        ) {
                                            descriptionValue2 = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            descriptionValue2 = nil
                                        }
                                        
                                        let descriptionValue3: String?
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyIPTCDictionary,
                                            kCGImagePropertyIPTCCaptionAbstract
                                        ) {
                                            descriptionValue3 = CGImageMetadataTagCopyValue(tag) as? String
                                        } else {
                                            descriptionValue3 = nil
                                        }
                                        
                                        if let descriptionValue, let descriptionValue2, let descriptionValue3 {
                                            description = descriptionValue == descriptionValue2 && descriptionValue == descriptionValue3
                                            ? descriptionValue
                                            : "Multiple values!"
                                        } else if descriptionValue != nil || descriptionValue2 != nil || descriptionValue3 != nil {
                                            description = "Multiple values!"
                                        }
                                        
                                        
                                        // Identifier
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:identifier" as CFString
                                        ) as String? {
                                            identifier = value
                                        }
                                        
                                        
                                        // Creator
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:creator" as CFString
                                        ) as String? {
                                            creator = value
                                        }
                                        
                                        
                                        // Source
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:source" as CFString
                                        ) as String? {
                                            source = value
                                        }
                                        
                                        
                                        // Rights
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "dc:rights" as CFString
                                        ) as String? {
                                            isPublicDomain = value == "Public domain"
                                        }
                                        
                                        
                                        // Persons
                                        var personList: [String] = []
                                        var personIndex = 0
                                        
                                        while let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata,
                                            nil,
                                            "iptcExt:PersonInImage[\(personIndex)]" as CFString
                                        ) as String? {
                                            personList.append(value)
                                            personIndex += 1
                                        }
                                        
                                        persons = personList.joined(separator: ", ")
                                        
                                        
                                        // Keywords
                                        var keywordList: [String] = []
                                        var keywordIndex = 0
                                        
                                        while let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata,
                                            nil,
                                            "dc:subject[\(keywordIndex)]" as CFString
                                        ) as String? {
                                            keywordList.append(value)
                                            keywordIndex += 1
                                        }
                                        
                                        keywords = keywordList.joined(separator: ", ")
                                        
                                        
                                        // Location
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "iptcExt:LocationCreatedSublocation" as CFString
                                        ) as String? {
                                            locationSublocation = value
                                        }
                                        
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "iptcExt:LocationCreatedCity" as CFString
                                        ) as String? {
                                            locationCity = value
                                        }
                                        
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "iptcExt:LocationCreatedProvinceState" as CFString
                                        ) as String? {
                                            locationProvince = value
                                        }
                                        
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "iptcExt:LocationCreatedCountryName" as CFString
                                        ) as String? {
                                            locationCountryName = value
                                        }
                                        
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "iptcExt:LocationCreatedCountryCode" as CFString
                                        ) as String? {
                                            locationCountryCode = value
                                        }
                                        
                                        if let value = CGImageMetadataCopyStringValueWithPath(
                                            metadata, nil, "iptcExt:LocationCreatedLocationName" as CFString
                                        ) as String? {
                                            locationLocationName = value
                                        }
                                        
                                        
                                        // GPS
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyGPSDictionary,
                                            kCGImagePropertyGPSLatitude
                                        ),
                                           let value = CGImageMetadataTagCopyValue(tag) as? String {
                                            locationLatitude = value
                                        }
                                        
                                        if let tag = CGImageMetadataCopyTagMatchingImageProperty(
                                            metadata,
                                            kCGImagePropertyGPSDictionary,
                                            kCGImagePropertyGPSLongitude
                                        ),
                                           let value = CGImageMetadataTagCopyValue(tag) as? String {
                                            locationLongitude = value
                                        }
                                    } else {
                                        print("Loading exif data failed")
                                    }
                                }
                                .gridColumnAlignment(.leading)
                            
                            Button(action: {
                                showingFilePicker.toggle()
                            }, label: {
                                Text("Select File")
                            })
                            .fileImporter(
                                isPresented: $showingFilePicker,
                                allowedContentTypes: [.png, .jpeg, .tiff]
                            ) { result in
                                switch result {
                                case .success(let url):
                                    filePath = url.path
                                    
                                case .failure(let error):
                                    print(error)
                                }
                            }
                        }
                    }
                    
                    Text("Descriptions")
                        .font(.headline)
                        .padding()
                    GridRow {
                        Text("Title")
                        TextField("", text: $title)
                    }
                    GridRow {
                        Text("Description")
                        TextField("", text: $description, axis: .vertical)
                    }
                    GridRow {
                        Text("Identifier")
                        TextField("e.g. Genograms-AppleArchive-Group01-Image01", text: $identifier)
                    }
                    GridRow {
                        Text("Photographer")
                        TextField("", text: $creator)
                    }
                    GridRow {
                        Text("Source")
                        TextField("e.g. Apple archive", text: $source)
                    }
                    GridRow {
                        Text("Public domain")
                        HStack {
                            Toggle(isOn: $isPublicDomain, label: {
                                
                            })
                            Spacer()
                        }
                    }
                    GridRow {
                        Text("Persons")
                        TextField("Space-Comma separated", text: $persons)
                    }
                    GridRow {
                        Text("Keywords")
                        TextField("Space-Comma separated", text: $keywords)
                    }
                    GridRow {
                        Text("Keep keywords")
                        HStack {
                            Toggle(isOn: $keepExistingKeywords, label: {
                                
                            })
                            Spacer()
                        }
                    }
                    
                    Text("Dates")
                        .font(.headline)
                        .padding()
                    GridRow {
                        Text("Date created")
                        TextField("Textual description, e.g. Between 1900 to 1910 for range, or Winter 2026", text: $dateCreated)
                    }
                    GridRow {
                        Text("Date created")
                        HStack {
                            TextField("Exact date, e.g. \(currentDate)", text: $dateCreatedAccurateString)
                                .onChange(of: dateCreatedAccurateString) {
                                    dateCreatedAccurate = parseDate(dateCreatedAccurateString) ?? Date()
                                }
                            Text("or")
                            DatePicker("", selection: Binding(
                                get: {
                                    dateCreatedAccurate ?? Date()
                                },
                                set: {
                                    dateCreatedAccurate = $0
                                }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.field)
                        }
                    }
                    GridRow {
                        Text("Date digitized")
                        HStack {
                            TextField("Exact date, e.g. \(currentDate)", text: $dateDigitizedString)
                                .onChange(of: dateDigitizedString) {
                                    dateDigitized = parseDate(dateDigitizedString) ?? Date()
                                }
                            Text("or")
                            DatePicker("", selection: Binding(
                                get: {
                                    dateDigitized ?? Date()
                                },
                                set: {
                                    dateDigitized = $0
                                }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.field)
                        }
                    }
                }
                
                Text("Location")
                    .font(.headline)
                    .padding()
                HStack {
                    TextField("Search Address, City, or Country", text: $locationSearchText)
                        .onChange(of: locationSearchText, {
                            searchLocation()
                        })
                        .onSubmit {
                            searchLocation()
                        }
                    Button("Search") {
                        searchLocation()
                    }
                }
                ZStack(alignment: .top) {
                    Map(position: $coordinates) {
                        if let coordinate = mapCoordinate {
                            MapCircle(
                                center: coordinate,
                                radius: coordinateAccuracyRadius
                            )
                            .foregroundStyle(.blue.opacity(0.2))
                            .stroke(.blue, lineWidth: 1)
                        }
                    }
                    .frame(height: 250)
                    if !locationSearchResults.isEmpty {
                        List {
                            ForEach(locationSearchResults, id: \.self) { mapItem in
                                Button {
                                    selectLocation(mapItem)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mapItem.name ?? "Unknown location")
                                            .font(.body)
                                        
                                        if let address = mapItem.address {
                                            Text(address.fullAddress)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxHeight: 200)
                        .padding(8)
                    }
                }
                
                Slider(value: $coordinatePrecision, in: 0...4, step: 1, onEditingChanged: {_ in
                    let precision = Int(coordinatePrecision)
                    
                    if let dotIndex = locationLatitude.firstIndex(of: ".") {
                        let endIndex = locationLatitude.index(
                            dotIndex,
                            offsetBy: min(
                                precision + 1,
                                locationLatitude.distance(from: dotIndex, to: locationLatitude.endIndex)
                            ),
                            limitedBy: locationLatitude.endIndex
                        ) ?? locationLatitude.endIndex
                        
                        locationLatitude = String(locationLatitude[..<endIndex])
                    }
                    
                    if let dotIndex = locationLongitude.firstIndex(of: ".") {
                        let endIndex = locationLongitude.index(
                            dotIndex,
                            offsetBy: min(
                                precision + 1,
                                locationLongitude.distance(from: dotIndex, to: locationLongitude.endIndex)
                            ),
                            limitedBy: locationLongitude.endIndex
                        ) ?? locationLongitude.endIndex
                        
                        locationLongitude = String(locationLongitude[..<endIndex])
                    }
                })
                .help("Decimal from 0 to 4 (lat/long): 0 = ±55/±36 km, 1 = ±5.6/±3.7 km, 2  = ±556/±365 m, 3 = ±56/±37 m, 4 = ±5,6/±3,7 m")
                HStack {
                    TextField("Latitude", text: $locationLatitude)
                        .onChange(of: locationLatitude, {
                            updateMapFromCoordinates()
                        })
                    TextField("Longitude", text: $locationLongitude)
                        .onChange(of: locationLongitude, {
                            updateMapFromCoordinates()
                        })
                }
                TextField("Sublocation or street", text: $locationSublocation)
                HStack {
                    TextField("City", text: $locationCity)
                    TextField("Province or County", text: $locationProvince)
                    TextField("Country", text: $locationCountryName)
                    TextField("Country Code", text: $locationCountryCode)
                }
                TextField("Full location name", text: $locationLocationName)
                
                HStack {
                    Button(action: {
                        do {
                            status = "Writing"
                            let metadataService = MetadataService()
                            try metadataService.writeMetadata(
                                filePath: filePath,
                                
                                // Dates
                                dateCreated: dateCreated,
                                dateCreatedAccurate: dateCreatedAccurate,
                                dateDigitized: dateDigitized,
                                
                                // Descriptions
                                title: title,
                                description: description,
                                identifier: identifier,
                                creator: creator,
                                source: source,
                                isPublicDomain: isPublicDomain,
                                persons: persons,
                                keywords: keywords,
                                keepExistingKeywords: keepExistingKeywords,
                                
                                // Location
                                locationSublocation: locationSublocation,
                                locationCity: locationCity,
                                locationProvince: locationProvince,
                                locationCountryName: locationCountryName,
                                locationCountryCode: locationCountryCode,
                                locationLocationName: locationLocationName,
                                locationLatitude: locationLatitude,
                                locationLongitude: locationLongitude
                            )
                            status = "Done"
                        } catch {
                            status = "Failed: \(error)"
                            print(error)
                        }
                    }, label: {
                        Text("Write Metadata")
                    })
                    Text(status)
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = locationSearchText
        
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard let response else {
                return
            }
            
            locationSearchResults = response.mapItems
            
            coordinates = .region(response.boundingRegion)
        }
    }
    
    private func selectLocation(_ mapItem: MKMapItem) {
        let address = mapItem.address
        let representations = mapItem.addressRepresentations
        
        locationSublocation = address?.shortAddress ?? ""
        locationCity = representations?.cityName ?? ""
        locationProvince = "" // Apple maps doesn't support province level
        locationCountryName = representations?.regionName ?? ""
        locationCountryCode = representations?.region?.identifier ?? ""
        
        locationLocationName = address?.fullAddress ?? ""
        
        let coordinate = mapItem.location.coordinate
        
        locationLatitude = "\(coordinate.latitude >= 0 ? "N" : "S")\(abs(coordinate.latitude))"
        locationLongitude = "\(coordinate.longitude >= 0 ? "E" : "W")\(abs(coordinate.longitude))"
        
        coordinates = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.05,
                    longitudeDelta: 0.05
                )
            )
        )
        
        locationSearchResults = []
    }
    
    private func updateMapFromCoordinates() {
        guard !locationLatitude.isEmpty,
              !locationLongitude.isEmpty else {
            return
        }
        
        let latitudeDirection = locationLatitude.first
        let longitudeDirection = locationLongitude.first
        
        guard let latitudeDirection,
              let longitudeDirection,
              let latitude = Double(locationLatitude.dropFirst()),
              let longitude = Double(locationLongitude.dropFirst()) else {
            return
        }
        
        let latitudeValue = latitudeDirection == "S" ? -latitude : latitude
        let longitudeValue = longitudeDirection == "W" ? -longitude : longitude
        
        let precision = Int(coordinatePrecision)
        
        let radius: CLLocationDistance
        
        switch precision {
        case 0:
            radius = 55_000
        case 1:
            radius = 5_550
        case 2:
            radius = 555
        case 3:
            radius = 55.5
        case 4:
            radius = 5.55
        default:
            radius = 0
        }
        
        let coordinate = CLLocationCoordinate2D(
            latitude: latitudeValue,
            longitude: longitudeValue
        )
        
        mapCoordinate = coordinate
        coordinateAccuracyRadius = radius
        
        coordinates = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: (radius * 2) / 111_000,
                    longitudeDelta: (radius * 2) / 111_000
                )
            )
        )
    }
    
    func parseDate(_ text: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = [
                // Month + year + time
                "MMMM yyyy HH:mm:ss",
                
                // Day + month + year
                "d MMMM yyyy",
                "dd MMMM yyyy",
                
                // Month + day + year
                "MMMM dd, yyyy",
                
                // Numeric dates
                "dd.MM.yyyy",
                "d.M.yyyy",
                "dd.MM.yy",
                "d.M.yy",
                "yyyy-MM-dd",
                "dd/MM/yyyy",
                
                // Month + year
                "MMMM yyyy",
                
                // Year only
                "yyyy",
                
                // Existing formats
                "d MMM yyyy"
            ]
            
            return formats.map {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.dateFormat = $0
                formatter.isLenient = false
                return formatter
            }
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }
        
        return nil
    }
}

#Preview {
    ContentView()
}
