//
//  TextCollectionViewCell.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 19.06.2026.
//

import UIKit

class TextCollectionViewCell: UICollectionViewCell {
    
    private let titleLabel = UILabel()
    private let height: CGFloat = 100
    private var previousBounds: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 8
        titleLabel.frame = CGRect(x: padding,
                                  y: 0,
                                  width: contentView.bounds.width - (padding * 2),
                                  height: height)
        previousBounds = bounds.size
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: height)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        /// If it's already rendered at the proposed size it can just return
        if previousBounds == layoutAttributes.size {
            return layoutAttributes
        } else {
            /// This will call sizeThatFits
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }
    }
    
    func configure(with news: News?) {
        titleLabel.text = news?.title
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
    }
}
