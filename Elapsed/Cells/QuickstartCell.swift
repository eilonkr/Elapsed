//
//  QuickstartCell.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

final class QuickstartCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastTimeLabel: UILabel!
    
    public var isLast: Bool!
    
    /// Provided: Title
    public var onStart: ((String) -> Void)?
    
    private var didLayout = false
    
    private var activity: Activity! {
        didSet {
            titleLabel.text = activity.title
            lastTimeLabel.text = "\(activity.lastRepeat?.formatted ?? "")"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didLayout {
            didLayout = true
            if !isLast {
                let separator = DashedSeparator(frame: CGRect(x: 0, y: bounds.maxY-1, width: bounds.width, height: 1))
                contentView.addSubview(separator)
            }
        }
    }
    
    public func configure(with activity: Activity) {
        self.activity = activity
    }
    
    @IBAction func start(_ sender: Any) {
        self.onStart?(self.activity.title)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
