//
//  NewsViewModel.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation
import Combine

protocol NewsViewModelProtocol {
    var newsPublisher: AnyPublisher<([News.ID], isNext: Bool), Never> { get }
    var offsetLimit: CGFloat { get }
    func resetPagination()
    func fetchNews() async
    func fetchNews(by id: News.ID) -> News?
}

@MainActor
final class NewsViewModel: NewsViewModelProtocol, ObservableObject {
    var newsPublisher: AnyPublisher<([News.ID], isNext: Bool), Never> {
        $news
            .dropFirst()
            .eraseToAnyPublisher()
    }
    @Published private var news: ([News.ID], isNext: Bool) = ([], isNext: false)
    var offsetLimit: CGFloat { pagination.offsetLimit }
    
    private var fetchTask: Task<Void, Never>? = nil
    private var newsStore: [News.ID: News] = [:]
    private let networkService: NewsNetworkServiceProtocol
    private var pagination = Pagination()
    
    init(networkService: NewsNetworkServiceProtocol) {
        self.networkService = networkService
        resetPagination()
    }
    
    func resetPagination() {
        fetchTask?.cancel()
        pagination.page = 1
        pagination.isFetching = false
        newsStore.removeAll(keepingCapacity: true)
    }
    
    func fetchNews() async {
        if let fetchTask = fetchTask, !fetchTask.isCancelled {
            return
        }
        
        fetchTask = Task {
            
            defer { fetchTask = nil }
            
            do {
                let news = try await networkService.fetchNews(with: pagination).news
                
                guard !Task.isCancelled else { return }
                
                news.toDict(&newsStore)
                self.news = (news.map { $0.id }, isNext: pagination.page != 1)
                pagination.hasNext = !news.isEmpty
            } catch {
                
                // TODO show error message
                
                print(error.localizedDescription)
                
            }
        }
    }
    
    func fetchNews(by id: News.ID) -> News? {
        newsStore[id]
    }
}
