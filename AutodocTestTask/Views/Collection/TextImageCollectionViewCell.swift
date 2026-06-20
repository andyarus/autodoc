//
//  TextImageCollectionViewCell.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 19.06.2026.
//

import UIKit

class TextImageCollectionViewCell: UICollectionViewCell {
    
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancelImageLoading()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageLoading()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 8
        titleLabel.frame = CGRect(x: padding,
                                  y: 0,
                                  width: contentView.bounds.width - (padding * 2),
                                  height: 32)
        imageView.frame = CGRect(x: 0,
                                 y: titleLabel.frame.height,
                                 width: contentView.bounds.width,
                                 height: contentView.bounds.height - titleLabel.frame.height)
    }
    
    func configure(with news: News? = nil) {
        titleLabel.text = news?.title
        imageView.image = nil
    }
    
    func setImage(with image: UIImage?) {
        imageView.image = image
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
    }
    
    private func cancelImageLoading() {
        guard let imageUrl = accessibilityIdentifier else { return }
        Task { await ImageLoader.shared.cancel(for: imageUrl) }
    }
}
