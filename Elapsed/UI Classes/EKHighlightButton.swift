//
//  EKHighlightButton.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 08/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import UIKit

class EKHighlightButton: UIButton {
    
    @IBInspectable public var isOval: Bool = false
    
    private lazy var accentColor: UIColor = backgroundColor ?? .white

    override public var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.backgroundColor = self.isHighlighted ? self.accentColor.darker() : self.accentColor
                
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _ = accentColor
        
        self.adjustsImageWhenHighlighted = false
        
        if isOval {
            layer.roundCorners(of: .oval)
        }
    }

}
