//
//  DashedSeperator.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

final class DashedSeparator: UIView {
    private var didLayout = false
    override func layoutSubviews() {
        if !didLayout {
            didLayout = true
            drawDottedLine(color: backgroundColor ?? UIColor.white.withAlphaComponent(0.2))
            backgroundColor = nil
        }
    }

}
