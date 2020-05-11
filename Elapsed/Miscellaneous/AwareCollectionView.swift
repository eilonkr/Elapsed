//
//  AwareCollectionView.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 22/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

final class AwareCollectionView: UICollectionView {
    private let noResultsString = "no results found"
    private let noItemsString = "it's pretty lonely in here :( \n \n how about adding some new activities?"
    
    private lazy var noContentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(white: 1, alpha: 0.4)
        label.font = kDefaultFont?.withSize(17.0)
        label.text = noItemsString
        label.numberOfLines = 0
        label.textAlignment = .center
        label.frame.size = label.sizeThatFits(.init(width: frame.width*0.9, height: .greatestFiniteMagnitude))
        label.isHidden = true
        addSubview(label)
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        noContentLabel.center = .init(x: bounds.midX, y: bounds.midY - 90)
    }
    
    func noResults(_ show: Bool) {
        noContentLabel.text = show ? noResultsString : noItemsString
    }
    
    override func reloadData() {
        super.reloadData()
        noContentLabel.isHidden = !(numberOfSections == .zero)
    }
}

