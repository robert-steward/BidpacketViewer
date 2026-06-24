import Foundation

final class BidpacketDownloadService {
    private let username: String
    private let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func downloadBidpacket(from urlString: String) async throws -> Data {
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
