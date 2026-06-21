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
    var task: Task<Void, Never>?
    private let refreshControl = UIRefreshControl()
    private var cancellables = Set<AnyCancellable>()
    
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
        setupRefreshControl()
        fetchData()
    }
    
    deinit {
        task?.cancel()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        viewModel.newsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (news, isNext) in
                guard let self else { return }
                self.applySnapshot(with: news, isNext: isNext)
                self.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
    }
    
    private func setupRefreshControl() {
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchData), for: .valueChanged)
    }
    
    @objc
    private func fetchData() {
        viewModel.resetPagination()
        task?.cancel()
        task = Task { [weak self] in
            await self?.viewModel.fetchNews()
        }
    }
}
