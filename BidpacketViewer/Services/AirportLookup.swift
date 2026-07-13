//
//  AirportLookup.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 7/6/26.
//

import Foundation

struct AirportInfo {
    let code: String
    let timeZoneID: String
    let country: String
    let region: String

    var isInternational: Bool {
        country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "united states"
    }
}

final class AirportLookup {
    static let shared = AirportLookup()

    private var airportsByCode: [String: AirportInfo] = [:]

    private init() {
        loadCSV()
    }

    func info(for code: String) -> AirportInfo? {
        airportsByCode[code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()]
    }

    func region(for code: String) -> String? {
        info(for: code)?.region
    }

    func country(for code: String) -> String? {
        info(for: code)?.country
    }

    func isInternational(_ code: String) -> Bool {
        info(for: code)?.isInternational ?? false
    }

    func regions(for stationCodes: some Sequence<String>) -> Set<String> {
        Set(stationCodes.compactMap { region(for: $0) })
    }

    func hasInternationalStation(in stationCodes: some Sequence<String>) -> Bool {
        stationCodes.contains { isInternational($0) }
    }
    
    func regions(for rotation: Rotation) -> Set<String> {
        guard let touches = rotation.touches else {
            return []
        }

        return regions(for: touches.keys)
    }

    private func loadCSV() {
        guard let url = Bundle.main.url(
            forResource: "airports_with_country_region",
            withExtension: "csv"
        ) else {
            print("AirportLookup: airports_with_country_region.csv not found in bundle.")
            return
        }

        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            parseCSV(contents)
        } catch {
            print("AirportLookup: could not read CSV: \(error)")
        }
    }

    private func parseCSV(_ contents: String) {
        let rows = contents
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        guard rows.count > 1 else { return }

        for row in rows.dropFirst() {
            let columns = parseCSVRow(row)

            guard columns.count >= 4 else {
                continue
            }

            let code = columns[0]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            guard !code.isEmpty else { continue }

            let airport = AirportInfo(
                code: code,
                timeZoneID: columns[1].trimmingCharacters(in: .whitespacesAndNewlines),
                country: columns[2].trimmingCharacters(in: .whitespacesAndNewlines),
                region: columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
            )

            airportsByCode[code] = airport
        }
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        for character in row {
            if character == "\"" {
                insideQuotes.toggle()
            } else if character == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        result.append(current)
        return result
    }
}
