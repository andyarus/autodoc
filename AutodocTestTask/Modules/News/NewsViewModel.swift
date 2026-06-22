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
    func openNews(by id: News.ID)
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
    private var pagination = Pagination()
    private weak var coordinator: AppCoordinatorProtocol?
    private let networkService: NewsNetworkServiceProtocol
    
    init(coordinator: AppCoordinatorProtocol,
         networkService: NewsNetworkServiceProtocol) {
        self.coordinator = coordinator
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
                guard !(error is CancellationError) else { return }
                alert(title: .localized("Error"), message: .localized("Error.requst"))
            }
        }
    }
    
    func fetchNews(by id: News.ID) -> News? {
        newsStore[id]
    }
    
    func openNews(by id: News.ID) {
        guard let urlString = fetchNews(by: id)?.fullUrl,
            let url = URL(string: urlString) else { return }
        coordinator?.open(url: url)
    }
    
    private func alert(title: String, message: String, confirmAction: (() -> Void)? = nil) {
        coordinator?.alert(title: title, message: message, confirmAction: confirmAction)
    }
}
