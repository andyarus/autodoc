//
//  NewsViewModel.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation
import Combine

protocol NewsViewModelProtocol {
    var newsPublisher: AnyPublisher<[News.ID], Never> { get }
    func fetchNews() async
    func fetchNews(by id: News.ID) -> News?
}

@MainActor
final class NewsViewModel: NewsViewModelProtocol, ObservableObject {
    var newsPublisher: AnyPublisher<[News.ID], Never> {
        $news
            .dropFirst()
            .eraseToAnyPublisher()
    }
    @Published private var news: [News.ID] = []
    
    private var newsStore: [News.ID: News] = [:]
    private let networkService: NewsNetworkServiceProtocol
    
    init(networkService: NewsNetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchNews() async {
        do {
            let news = try await networkService.fetchNews().news
            news.toDict(&newsStore)
            self.news = news.map { $0.id }
        } catch {
            
            // TODO show error message
            
            print(error.localizedDescription)
        }
    }
    
    func fetchNews(by id: News.ID) -> News? {
        newsStore[id]
    }
}
