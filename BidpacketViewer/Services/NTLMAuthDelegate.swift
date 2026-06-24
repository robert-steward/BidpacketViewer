//
//  NTLMAuthDelegate.swift
//  BidpacketViewer
//
//  Created by Robert Steward on 6/23/26.
//

import Foundation

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

