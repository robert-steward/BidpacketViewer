//
//  LocalBidpacketStore.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/23/26.
//

import Foundation

enum LocalBidpacketStore {
    static let folderName = "DownloadedBidpackets"
    static let activeBidpacketFileNameKey = "activeBidpacketFileName"

    static func downloadsDirectory() throws -> URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let folderURL = documentsURL.appendingPathComponent(folderName)

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
        }

        return folderURL
    }

    static func save(_ data: Data, fileName: String) throws -> URL {
        let safeName = sanitizedFileName(fileName)
        let fileURL = try downloadsDirectory().appendingPathComponent(safeName)

        try data.write(to: fileURL, options: .atomic)

        return fileURL
    }

    static func load(fileName: String) throws -> Data {
        let safeName = sanitizedFileName(fileName)
        let fileURL = try downloadsDirectory().appendingPathComponent(safeName)

        return try Data(contentsOf: fileURL)
    }

    static func localFiles() throws -> [URL] {
        let folderURL = try downloadsDirectory()

        return try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() == "json" }
        .sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    static func setActiveBidpacket(fileName: String) {
        UserDefaults.standard.set(fileName, forKey: activeBidpacketFileNameKey)
    }

    static func activeBidpacketFileName() -> String? {
        UserDefaults.standard.string(forKey: activeBidpacketFileNameKey)
    }

    private static func sanitizedFileName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
    }
}
