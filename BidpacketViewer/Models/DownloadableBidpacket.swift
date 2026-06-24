//
//  DownloadableBidpacket.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/23/26.
//

import Foundation

struct DownloadableBidpacket: Identifiable, Hashable {
    let id: String
    let displayName: String
    let fileName: String

    let base: String?
    let aircraft: String?
    let month: Int?
    let year: Int?

    let remotePath: String
}
