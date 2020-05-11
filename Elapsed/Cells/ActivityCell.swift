//
//  ActivityCell.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

class ActivityCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var averageTimeLabel: UILabel!
    @IBOutlet weak var lastTime: UILabel!
    
    public var activity: Activity!
    
    typealias Handler = (Activity) -> Void
    public var onStart: Handler?
    public var onShowMore: Handler?
    
    public var appearFactor: Double = 0.0
    
    private var didLayout = true
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        didLayout = false
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var newFrame = layoutAttributes.frame
        newFrame.size.height = CGFloat(ceilf(Float(size.height)))
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyDesign()
        if !didLayout {
            didLayout = true
            alpha = 0.0
            transform = transform.translatedBy(x: 0, y: 20)
            
            delay(appearFactor) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.transform = .identity
                    self.alpha = 1.0
                })
            }
        }
    }
    
    private func applyDesign() {
        layer.cornerRadius = 10
        layer.applyShadow()
        layer.shadowRadius = 10
    }
    
    public func configure(with activity: Activity) {
        titleLabel.text = activity.title + " (\(activity.repeats.count))"
        averageTimeLabel.text = activity.average?.timerString()
        lastTime.text = activity.lastRepeat?.formatted
        
        self.activity = activity
    }
    
    @IBAction func startTapped(_ sender: Any) {
        self.onStart?(self.activity)
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        self.onShowMore?(self.activity)
    }
}

