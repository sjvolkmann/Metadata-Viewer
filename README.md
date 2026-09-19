# Metadata Viewer
A native macOS application for viewing and editing metadata in archival photographs and scanned images.
Metadata Viewer is designed for working with historical photographs, family archives, and high-resolution scans. It provides a convenient SwiftUI interface for editing common XMP, IPTC, EXIF, and GPS metadata while using [ExifTool](https://exiftool.org/) for reliable metadata writing.
## Features
* View existing image metadata
* Edit XMP, IPTC, EXIF, and GPS metadata
* Human-readable date entry with support for natural date formats
* Accurate creation and digitization dates
* Location search using MapKit
* Latitude and longitude entry with coordinate accuracy
* Archival location metadata including:
  * Sublocation
  * City
  * Province/State
  * Country
  * Country code
  * World region
  * Location name
* Person-in-image metadata
* Keywords with the option to preserve existing keywords
* Title, description, identifier, creator, and source metadata
* Copyright metadata
* Public-domain handling
* Preservation of filesystem creation and modification dates when metadata is written
* Configurable ExifTool executable path
* Configurable copyright text
## Metadata standards
Metadata Viewer works with several metadata standards simultaneously to improve interoperability between applications.
### XMP
Supports metadata including:
* Dublin Core (`XMP-dc`)
* Photoshop (`XMP-photoshop`)
* IPTC Extension (`XMP-iptcExt`)
* XMP Exif (`XMP-exif`)
### IPTC
Supports legacy IPTC fields including:
* Object Name
* Caption-Abstract
* Keywords
* Date Created
* Time Created
* Province-State
* Country-Primary Location Name
* Copyright Notice
### EXIF
Supports fields including:
* Date/Time Original
* GPS coordinates
* GPS processing method
* GPS map datum
* GPS speed

The application writes related values to multiple metadata standards where appropriate so that the resulting files remain useful across different software.
## Supported image formats
The application currently supports:
* JPEG
* PNG
* TIFF

The primary use case is high-resolution TIFF scans of historical photographs.
## Requirements
* macOS 27
* Xcode
* ExifTool (recommended using Brew)

ExifTool must be installed separately. Its path can be configured in the application's Settings.
The default path is:
```text
/opt/homebrew/bin/exiftool
```
This is the typical Homebrew installation path on Apple Silicon Macs.
## Architecture
The application is intentionally small and uses a straightforward SwiftUI architecture.
* `MetadataViewerApp.swift` — application entry point and Settings scene
* `ContentView.swift` — metadata editor interface and metadata reading
* `SettingsView.swift` — application settings
* `MetadataService.swift` — metadata writing through ExifTool

Metadata is read using Apple's Image I/O framework, while ExifTool is used for writing metadata.
## Why this exists
This project was created for managing metadata in a personal historical photograph archive.
Historical photographs often contain information that is important for future generations but cannot be represented by the image itself: names, dates, places, sources, identifiers, and the circumstances in which a photograph was digitized.
The goal of Metadata Viewer is to make that information easy to enter and preserve without having to work directly with command-line metadata tools for every photograph.
