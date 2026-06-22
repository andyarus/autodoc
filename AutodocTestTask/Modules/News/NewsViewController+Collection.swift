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
        let estimatedHeight = TextImageCollectionViewCell.estimatedHeight
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
        collectionView.delegate = self
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
                    await MainActor.run {
                        /// Protection on cell reuse
                        guard cell.accessibilityIdentifier == imageUrl else { return }
                        cell.setImage(with: image)
                    }
                } catch {
                    guard !(error is CancellationError) else { return }
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
    func applySnapshot(with items: [News.ID], isNext: Bool) {
        var snapshot = isNext
            ? dataSource.snapshot()
            : NSDiffableDataSourceSnapshot<Section, News.ID>()
        if !isNext { snapshot.appendSections([.main]) }
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: isNext)
    }
}

// MARK: - UICollectionViewDelegate
extension NewsViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /// Pagination
        let contentHeight = scrollView.contentSize.height
        let offsetY = scrollView.contentOffset.y
        let height = scrollView.frame.size.height
        let offset = contentHeight - offsetY - height
        guard offset < viewModel.offsetLimit, offset > 0 else { return } // !scrollView.isDecelerating
        
        task = Task { [weak self] in
            await self?.viewModel.fetchNews()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemID = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.openNews(by: itemID)
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
