//
//  SizingTableView.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 09/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import UIKit

class SizingTableView: UITableView {
    override open func layoutSubviews() {
        super.layoutSubviews()
        if frame.size != intrinsicContentSize {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        var cellsHeight: CGFloat = .zero
        var headersHeight: CGFloat = .zero
        
        for s in 0 ..< numberOfSections {
            headersHeight += rectForHeader(inSection: s).height
            for r in 0 ..< min(numberOfRows(inSection: s), 10) {
                cellsHeight += rectForRow(at: IndexPath(row: r, section: 0)).height
            }
        }
        return .init(width: frame.width, height: cellsHeight + headersHeight)
    }
}

class DefaultTableView: UITableView {
    override open var intrinsicContentSize: CGSize {
        return .zero
    }
}
