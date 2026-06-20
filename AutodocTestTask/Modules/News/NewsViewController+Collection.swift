//
//  NewsViewController+Collection.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 16.06.2026.
//

import UIKit

extension NewsViewController {
    // MARK: - Types
    enum Section: nonisolated Hashable {
        case main
    }
    
    // MARK: - Compositional Layout Setup
    func setupCollectionView() {
        let estimatedHeight = view.bounds.width * 3/4
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(estimatedHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(estimatedHeight)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            
            return section
        }
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.prefetchDataSource = self
        view.addSubview(collectionView)
    }
    
    func setupDataSource() {
        let textCellRegistration = UICollectionView.CellRegistration<TextCollectionViewCell, News.ID> { [weak self] (cell, indexPath, itemID) in
            guard let self else { return }
            let item = self.viewModel.fetchNews(by: itemID)
            cell.configure(with: item) 
        }
        let textImageCellRegistration = UICollectionView.CellRegistration<TextImageCollectionViewCell, News.ID> { [weak self] (cell, indexPath, itemID) in
            guard let self else { return }
            let item = self.viewModel.fetchNews(by: itemID)
            cell.configure(with: item)
            guard let imageUrl = item?.titleImageUrl else { return }
            /// Store imageUrl inside the cell to automatically cancel it upon reuse
            cell.accessibilityIdentifier = imageUrl
            
            Task {
                do {
                    let image = try await ImageLoader.shared.loadImage(from: imageUrl)
                    /// Protection against cell reuse
                    guard cell.accessibilityIdentifier == imageUrl else { return }
                    await MainActor.run { cell.setImage(with: image) }
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, News.ID>(collectionView: collectionView) {
            [weak self] collectionView, indexPath, itemID in
            if let item = self?.viewModel.fetchNews(by: itemID), item.hasImage {
                return collectionView.dequeueConfiguredReusableCell(using: textImageCellRegistration, for: indexPath, item: itemID)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: itemID)
            }
        }
    }
    
    // MARK: - Snapshot
    func applySnapshot(with items: [News.ID]) {
        var snapshot = dataSource.snapshot()
        if snapshot.sectionIdentifiers.contains(.main) {
            snapshot.appendItems(items)
        } else {
            snapshot.appendSections([.main])
            snapshot.appendItems(items)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension NewsViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let itemID = dataSource.itemIdentifier(for: indexPath),
                  let imageUrl = viewModel.fetchNews(by: itemID)?.titleImageUrl else { continue }
            Task { await ImageLoader.shared.prefetchImage(from: imageUrl) }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let itemID = dataSource.itemIdentifier(for: indexPath),
                  let imageUrl = viewModel.fetchNews(by: itemID)?.titleImageUrl else { continue }
            Task { await ImageLoader.shared.cancel(for: imageUrl) }
        }
    }
}
