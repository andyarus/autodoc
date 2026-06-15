//
//  NewsViewController.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import UIKit
import Combine

final class NewsViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: any NewsViewModelProtocol
    
    init(viewModel: any NewsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        Task { await viewModel.fetchNews() }
    }
    
    private func setupBindings() {
        viewModel.newsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] news in
                self?.updateUI(with: news)
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with news: [News]) {
    }
}
