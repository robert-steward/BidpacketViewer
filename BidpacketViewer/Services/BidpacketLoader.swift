//
//  BidpacketLoader.swift
//  BidpacketViewer
//

import Foundation

struct LoadedBidpacket {
    let bidpacket: Bidpacket
    let name: String?
    let base: String?

    var aircraft: String {
        guard let name else { return "—" }
        return String(name.split(separator: "_").first ?? "—")
    }
}

enum BidpacketLoader {

    static func loadSampleBidpacket() throws -> LoadedBidpacket {
        guard let url = Bundle.main.url(
            forResource: "sample_bidpacket",
            withExtension: "json"
        ) else {
            throw NSError(
                domain: "BidpacketLoader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "sample_bidpacket.json not found"]
            )
        }

        let data = try Data(contentsOf: url)
        return try loadBidpacketPackage(from: data)
    }

    static func loadBidpacket(from data: Data) throws -> LoadedBidpacket {
        try loadBidpacketPackage(from: data)
    }

    private static func loadBidpacketPackage(from data: Data) throws -> LoadedBidpacket {
        let decoder = JSONDecoder()
        let file = try decoder.decode(BidpacketFile.self, from: data)

        return LoadedBidpacket(
            bidpacket: file.payload,
            name: file.name,
            base: file.base
        )
    }
}
