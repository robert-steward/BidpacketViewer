//
//  PlaceholderWorkspaceView.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/15/26.
//

import SwiftUI

struct PlaceholderWorkspaceView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 54))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.largeTitle.bold())

            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
    }
}
