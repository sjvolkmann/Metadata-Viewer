//
//  EditSheetGeodataView.swift
//  Metadata Viewer
//
//  Created by Serafin Volkmann on 26.09.2026.
//  Copyright © 2026 Killarnee. All rights reserved.
//

import MapKit
import SwiftUI

struct EditSheetGeodataView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 49.0069,
                longitude: 8.4037
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
    )
    
    @State private var searchResults: [MKMapItem] = []
    @State private var coordinatePrecision: Double = 4
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var coordinateAccuracyRadius: CLLocationDistance = 0
    
    @State private var selectedLatitude: String = ""
    @State private var selectedLongitude: String = ""
    @State private var selectedSublocation: String = ""
    @State private var selectedCity: String = ""
    @State private var selectedProvince: String = ""
    @State private var selectedCountryName: String = ""
    @State private var selectedCountryCode: String = ""
    @State private var selectedLocationName: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                ZStack(alignment: .top) {
                    Map(position: $mapPosition) {
                        if let coordinate = selectedCoordinate {
                            MapCircle(
                                center: coordinate,
                                radius: coordinateAccuracyRadius
                            )
                            .foregroundStyle(.blue.opacity(0.2))
                            .stroke(.blue, lineWidth: 1)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: 393)
                    
                    if !searchResults.isEmpty {
                        List {
                            ForEach(searchResults, id: \.self) { mapItem in
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
            }
            .padding([.vertical, .leading], 15)
            .padding(.trailing, 7.5)
            .frame(width: 350)
            VStack {
                HStack {
                    TextField(
                        "Search Address, City, or Country",
                        text: $searchText
                    )
                    .onChange(of: searchText, {
                        searchLocation()
                    })
                    .onSubmit {
                        searchLocation()
                    }
                    
                    Button("Search") {
                        searchLocation()
                    }
                }
                Slider(
                    value: $coordinatePrecision,
                    in: 0...4,
                    step: 1,
                    onEditingChanged: { _ in
                        let precision = Int(coordinatePrecision)
                        
                        if let dotIndex = selectedLatitude.firstIndex(of: ".") {
                            let endIndex = selectedLatitude.index(
                                dotIndex,
                                offsetBy: min(
                                    precision + 1,
                                    selectedLatitude.distance(
                                        from: dotIndex,
                                        to: selectedLatitude.endIndex
                                    )
                                ),
                                limitedBy: selectedLatitude.endIndex
                            ) ?? selectedLatitude.endIndex
                            
                            selectedLatitude = String(selectedLatitude[..<endIndex])
                        }
                        
                        if let dotIndex = selectedLongitude.firstIndex(of: ".") {
                            let endIndex = selectedLongitude.index(
                                dotIndex,
                                offsetBy: min(
                                    precision + 1,
                                    selectedLongitude.distance(
                                        from: dotIndex,
                                        to: selectedLongitude.endIndex
                                    )
                                ),
                                limitedBy: selectedLongitude.endIndex
                            ) ?? selectedLongitude.endIndex
                            
                            selectedLongitude = String(selectedLongitude[..<endIndex])
                        }
                    }
                )
                .help("Decimal from 0 to 4 (lat/long): 0 = ±55/±36 km, 1 = ±5.6/±3.7 km, 2  = ±556/±365 m, 3 = ±56/±37 m, 4 = ±5,6/±3,7 m")
                
                HStack {
                    TextField(
                        "Latitude",
                        text: $selectedLatitude
                    )
                    .onChange(of: selectedLatitude, {
                        updateMapFromSelectedCoordinates()
                    })
                    
                    TextField(
                        "Longitude",
                        text: $selectedLongitude
                    )
                    .onChange(of: selectedLongitude, {
                        updateMapFromSelectedCoordinates()
                    })
                }
                
                TextField(
                    "Sublocation or street",
                    text: $selectedSublocation
                )
                
                HStack {
                    TextField(
                        "City",
                        text: $selectedCity
                    )
                    
                    TextField(
                        "Province or County",
                        text: $selectedProvince
                    )
                    
                    TextField(
                        "Country",
                        text: $selectedCountryName
                    )
                    
                    TextField(
                        "Country Code",
                        text: $selectedCountryCode
                    )
                }
                
                TextField(
                    "Full location name",
                    text: $selectedLocationName
                )
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
                        dismiss()
                    } label: {
                        Text("Fill Fields")
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
    
    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard let response else {
                return
            }
            
            searchResults = response.mapItems
            
            mapPosition = .region(response.boundingRegion)
        }
    }
    
    private func selectLocation(_ mapItem: MKMapItem) {
        let address = mapItem.address
        let representations = mapItem.addressRepresentations
        
        selectedSublocation = address?.shortAddress ?? ""
        selectedCity = representations?.cityName ?? ""
        selectedProvince = ""
        selectedCountryName = representations?.regionName ?? ""
        selectedCountryCode = representations?.region?.identifier ?? ""
        
        selectedLocationName = address?.fullAddress ?? ""
        
        let coordinate = mapItem.location.coordinate
        
        selectedLatitude = "\(coordinate.latitude >= 0 ? "N" : "S")\(abs(coordinate.latitude))"
        
        selectedLongitude = "\(coordinate.longitude >= 0 ? "E" : "W")\(abs(coordinate.longitude))"
        
        selectedCoordinate = coordinate
        
        mapPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.05,
                    longitudeDelta: 0.05
                )
            )
        )
        
        searchResults = []
    }
    
    private func updateMapFromSelectedCoordinates() {
        guard !selectedLatitude.isEmpty,
              !selectedLongitude.isEmpty else {
            return
        }
        
        let latitudeDirection = selectedLatitude.first
        let longitudeDirection = selectedLongitude.first
        
        guard let latitudeDirection,
              let longitudeDirection,
              let latitude = Double(selectedLatitude.dropFirst()),
              let longitude = Double(selectedLongitude.dropFirst()) else {
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
        
        selectedCoordinate = coordinate
        coordinateAccuracyRadius = radius
        
        mapPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: (radius * 2) / 111_000,
                    longitudeDelta: (radius * 2) / 111_000
                )
            )
        )
    }
}

#Preview {
    EditSheetGeodataView()
}
