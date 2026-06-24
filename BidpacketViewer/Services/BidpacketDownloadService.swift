import Foundation

struct RemoteBidpacketListResponse: Decodable {
    let success: Bool
    let base: String?
    let files: [RemoteBidpacketFile]
    let message: String?
}

struct RemoteBidpacketFile: Decodable, Identifiable, Hashable {
    var id: String { name }

    let name: String
    let displayName: String?
    let size: Int?
    let modified: String?

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case size
        case modified
    }

    var title: String {
        displayName ?? name
    }

    var sizeText: String {
        guard let size else { return "Unknown size" }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file

        return formatter.string(fromByteCount: Int64(size))
    }
}

final class BidpacketDownloadService {
    private let username: String
    private let password: String

    private let serverRoot = "https://rotationscorer.alpa.org"

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func listBidpackets(base: String) async throws -> [RemoteBidpacketFile] {
        let urlString = "\(serverRoot)/site_content/list_bidpackets.php?base=\(base)"
        let data = try await fetchData(from: urlString)

        let response = try JSONDecoder().decode(
            RemoteBidpacketListResponse.self,
            from: data
        )

        guard response.success else {
            throw NSError(
                domain: "BidpacketDownloadService",
                code: 10,
                userInfo: [
                    NSLocalizedDescriptionKey: response.message ?? "Server returned an unsuccessful bidpacket list response."
                ]
            )
        }

        return response.files
    }

    func downloadBidpacket(base: String, fileName: String) async throws -> Data {
        let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName

        let urlString = "\(serverRoot)/site_content/saved_summaries_by_base/\(base)/\(encodedFileName)"

        return try await fetchData(from: urlString)
    }

    func downloadBidpacket(from urlString: String) async throws -> Data {
        try await fetchData(from: urlString)
    }

    private func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NSError(
                domain: "BidpacketDownloadService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid download URL."]
            )
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let delegate = NTLMAuthDelegate(username: username, password: password)

        let session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )

        defer {
            session.invalidateAndCancel()
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "BidpacketDownloadService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No HTTP response from server."]
            )
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "BidpacketDownloadService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server returned HTTP \(httpResponse.statusCode)."]
            )
        }

        return data
    }
}
