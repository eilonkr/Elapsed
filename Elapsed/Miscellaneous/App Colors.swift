//
//  App Colors.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 23/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

public struct AppColors {
    
    static var secondaryBackground: UIColor {
        return UIColor { (traitCollection) -> UIColor in
            if traitCollection.userInterfaceStyle == .light {
                return .white
            } else {
                return .secondarySystemBackground
            }
        }
    }
    
    static var oppositeBackground: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .light ? .black : .white
        }
    }
    
    static var background1 = UIColor(red: 17/255, green: 50/255, blue: 86/255, alpha: 1.00)
    static var background2 = UIColor(red: 60/255, green: 101/255, blue: 134/255, alpha: 1.0)
    
    static var blue  = UIColor(red: 0.286, green: 0.565, blue: 0.882, alpha: 1.00)
    static var red   = UIColor(red: 0.831, green: 0.447, blue: 0.447, alpha: 1.00)
    static var green = UIColor(red: 0.098, green: 0.808, blue: 0.565, alpha: 1.00)
    
    
}



