//
//  GlossaryInfoButton.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 7/14/26.
//

import SwiftUI

struct GlossaryInfoButton: View {
    let term: String

    @State private var showsDefinition = false

    private var entry: GlossaryEntry? {
        GlossaryCatalog.entry(for: term)
    }

    var body: some View {
        if let entry {
            Button {
                showsDefinition = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Information about \(entry.term)")
            .popover(
                isPresented: $showsDefinition,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                GlossaryInfoPopover(entry: entry)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

private struct GlossaryInfoPopover: View {
    let entry: GlossaryEntry

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(entry.term)
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            Text(entry.definition)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let example = entry.example,
               !example.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Example")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(example)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
