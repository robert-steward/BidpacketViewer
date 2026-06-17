//
//  BidpacketLoader.swift
//  BidpacketViewer
//

import Foundation

enum BidpacketLoader {

    static func loadSampleBidpacket() throws -> Bidpacket {
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

        let decoder = JSONDecoder()
        let file = try decoder.decode(BidpacketFile.self, from: data)
        return file.payload
    }

    // NEW
    static func loadBidpacket(from data: Data) throws -> Bidpacket {
        let decoder = JSONDecoder()
        let file = try decoder.decode(BidpacketFile.self, from: data)
        return file.payload
    }
}
