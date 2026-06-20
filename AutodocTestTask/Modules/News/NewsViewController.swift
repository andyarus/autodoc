//
//  NewsViewController.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import UIKit
import Combine

final class NewsViewController: UIViewController {
    
    // MARK: - Properties
    let viewModel: any NewsViewModelProtocol
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, News.ID>!
    
    private var cancellables = Set<AnyCancellable>()
    private var task: Task<Void, Never>?
    
    // MARK: - Init
    init(viewModel: any NewsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupCollectionView()
        setupDataSource()
        
        task = Task { [weak self] in await self?.viewModel.fetchNews() }
    }
    
    deinit {
        task?.cancel()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        viewModel.newsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] news in
                self?.applySnapshot(with: news)
            }
            .store(in: &cancellables)
    }
}
