//
//  NewsViewModel.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation
import Combine

protocol NewsViewModelProtocol {
    var newsPublisher: AnyPublisher<[News], Never> { get }
    func fetchNews() async
}

@MainActor
final class NewsViewModel: NewsViewModelProtocol, ObservableObject {
    var newsPublisher: AnyPublisher<[News], Never> {
        $news
            .dropFirst()
            .eraseToAnyPublisher()
    }
    @Published private var news: [News] = []
    private let networkService: NewsNetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NewsNetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchNews() async {
        do {
            news = try await networkService.fetchNews().news
        } catch {
            print(error.localizedDescription)
        }
    }
}
