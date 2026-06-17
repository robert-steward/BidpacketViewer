import SwiftUI

struct LoginTestView: View {
    @Bindable var viewModel: BidpacketViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var result = "Not Connected"
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("IIS Login Test")
                .font(.largeTitle)

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(maxWidth: 400)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)

            Button(isLoading ? "Testing..." : "Test Server") {
                testServer()
            }
            .disabled(isLoading || username.isEmpty || password.isEmpty)
            
            Button("Load Downloaded Bidpacket") {
                loadDownloadedBidpacket()
            }

            ScrollView {
                Text(result)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .padding()
    }

    func loadDownloadedBidpacket() {

        do {

            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let fileURL = documentsURL.appendingPathComponent(
                "downloaded_bidpacket.json"
            )

            let data = try Data(contentsOf: fileURL)

            viewModel.loadFromData(data)

            result = "Loaded downloaded bidpacket."

        } catch {

            result = error.localizedDescription

        }
    }
    
    func saveDownloadedBidpacket(_ data: Data) {
        do {
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let fileURL = documentsURL.appendingPathComponent(
                "downloaded_bidpacket.json"
            )

            try data.write(to: fileURL, options: .atomic)

            print("Saved downloaded bidpacket to:", fileURL)
        } catch {
            print("Failed to save downloaded bidpacket:", error)
        }
    }
    
    
    func testServer() {
        isLoading = true
        result = "Connecting..."

        guard let url = URL(string: "https://rotationscorer.alpa.org/bidpackets/sample_bidpacket.json") else {
            result = "Bad URL"
            isLoading = false
            return
        }

        let delegate = NTLMAuthDelegate(
            username: username,
            password: password
        )

        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error {
                    result = "ERROR:\n\(error.localizedDescription)"
                    return
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                var output = "HTTP Status: \(statusCode)\n\n"

                if let data {
                    saveDownloadedBidpacket(data)

                    output += "Downloaded \(data.count) bytes\n"
                    output += "Saved as downloaded_bidpacket.json\n\n"

                    if let preview = String(data: data.prefix(500), encoding: .utf8) {
                        output += "Preview:\n\(preview)"
                    }
                }
                
                else {
                    output += "No data returned"
                }
                
                result = output
            }
        }
        .resume()
    }
}

final class NTLMAuthDelegate: NSObject, URLSessionTaskDelegate {
    private let username: String
    private let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        let method = challenge.protectionSpace.authenticationMethod

        if method == NSURLAuthenticationMethodNTLM ||
            method == NSURLAuthenticationMethodNegotiate {

            let credential = URLCredential(
                user: username,
                password: password,
                persistence: .forSession
            )

            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

#Preview {
    LoginTestView(viewModel: BidpacketViewModel())

}
