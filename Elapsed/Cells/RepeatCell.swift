//
//  RepeatCell.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 23/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

class RepeatCell: UITableViewCell {

    private var dateLabel: UILabel!
    private var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        dateLabel = UILabel.defaultLabel(text: "", font: kDefaultFont!.withSize(17.0), color: AppColors.blue.withAlphaComponent(0.8))
        timeLabel = UILabel.defaultLabel(text: "", font: kDefaultFont!.withSize(17.0), color: AppColors.blue)
        contentView.addSubview(dateLabel)
        contentView.addSubview(timeLabel)
        
        
        let padding: CGFloat = 8.0
        dateLabel.vfix(in: contentView, padding: padding)
        timeLabel.vfix(in: contentView, padding: padding)
        
        dateLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        timeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
    }

    public func configure(with _repeat: Repeat) {
        dateLabel?.text = _repeat.date.shortFormat()
        timeLabel?.text = "\(_repeat.formatted)"
    }
    
}
