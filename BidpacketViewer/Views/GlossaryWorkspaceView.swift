//
//  GlossaryWorkspaceView.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 7/13/26.
//

import SwiftUI


struct GlossaryWorkspaceView: View {
    @State private var searchText = ""


    private var filteredSections: [GlossarySection] {
        let trimmedSearch = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return GlossaryCatalog.sections
        }

        let query = trimmedSearch.lowercased()

        return GlossaryCatalog.sections.compactMap { section in
            let matchingEntries = section.entries.filter { entry in
                entry.term.lowercased().contains(query) ||
                entry.definition.lowercased().contains(query) ||
                (entry.example?.lowercased().contains(query) ?? false)
            }

            guard !matchingEntries.isEmpty else {
                return nil
            }

            return GlossarySection(
                title: section.title,
                entries: matchingEntries
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSections) { section in
                    Section(section.title) {
                        ForEach(section.entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.term)
                                    .font(.headline)

                                Text(entry.definition)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let example = entry.example {
                                    Text("Example: \(example)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Glossary")
            .searchable(
                text: $searchText,
                prompt: "Search terms"
            )
        }
    }
}

#Preview {
    GlossaryWorkspaceView()
}
