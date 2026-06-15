//
//  NewsNetworkService.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation

protocol NewsNetworkServiceProtocol {
    func fetchNews() async throws -> NewsResponse
}

final class NewsNetworkService: NewsNetworkServiceProtocol {
    
    private let client: NetworkClientProtocol
    
    init(client: NetworkClientProtocol) {
        self.client = client
    }
    
    func fetchNews() async throws -> NewsResponse {
        let news: NewsResponse = try await client.request(NewsTarget.news)
        return news
    }
}
