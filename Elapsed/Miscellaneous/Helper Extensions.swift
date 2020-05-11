//
//  Helpers.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

func delay(_ time: TimeInterval, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
}

extension Array where Element: Equatable {
    func unique() -> [Element] {
        var filtered = self
        var removed = 0
        for (idx, elem) in self.enumerated() {
            if filtered.filter({ $0 == elem }).count > 1 {
                filtered.remove(at: idx-removed)
                removed += 1
            }
        }
        return filtered
    }
}

extension UIView {
    var relativeCenter: CGPoint {
        return .init(x: bounds.width/2, y: bounds.height/2)
    }
}

extension CGSize {
    static func square(_ value: CGFloat) -> CGSize {
        return .init(width: value, height: value)
    }
}

extension CGAffineTransform {
    static func evenScale(_ value: CGFloat) -> CGAffineTransform {
        return .init(scaleX: value, y: value)
    }
}

extension UIEdgeInsets {
    static func even(_ value: CGFloat) -> UIEdgeInsets {
        return .init(top: value, left: value, bottom: value, right: value)
    }
}

extension CALayer {
    func applyShadow() {
        shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        shadowOpacity = 1.0
        shadowOffset = .init(width: 0, height: 2.0)
        shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowRadius = 1.0
    }
    
    func applyGradient(ofColors colors: [UIColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.colors = colors.map {$0.cgColor}
        gradientLayer.startPoint = .init(x: 0.0, y: 0.5)
        gradientLayer.endPoint = .init(x: 1.0, y: 0.5)
        insertSublayer(gradientLayer, at: 0)
    }
    
    func roundCorners(of type: RoundedRectType) {
        var roundValue: CGFloat?
        switch type {
            case .oval:
                roundValue = bounds.height / 2
            case .regular:
                roundValue = min(min(10.0,  bounds.height/2), bounds.width/2)
        }
        
        cornerRadius = roundValue ?? 0
    }
    
    enum RoundedRectType { case oval, regular }
}

extension UIColor {
    func lighter(by percentage: CGFloat = 10.0) -> UIColor {
        return self.adjust(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat = 10.0) -> UIColor {
        return self.adjust(by: -abs(percentage))
    }
    
    func adjust(by percentage: CGFloat) -> UIColor {
        var alpha, hue, saturation, brightness, red, green, blue, white : CGFloat
        (alpha, hue, saturation, brightness, red, green, blue, white) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        
        let multiplier = percentage / 100.0
        
        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newBrightness: CGFloat = max(min(brightness + multiplier*brightness, 1.0), 0.0)
            return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
        }
        else if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let newRed: CGFloat = min(max(red + multiplier*red, 0.0), 1.0)
            let newGreen: CGFloat = min(max(green + multiplier*green, 0.0), 1.0)
            let newBlue: CGFloat = min(max(blue + multiplier*blue, 0.0), 1.0)
            return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
        }
        else if self.getWhite(&white, alpha: &alpha) {
            let newWhite: CGFloat = (white + multiplier*white)
            return UIColor(white: newWhite, alpha: alpha)
        }
        
        return self
    }
}

extension UIView {
    func drawDottedLine(color: UIColor) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [7, 3] // 7 is the length of dash, 3 is length of the gap.
        
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: bounds.minX, y: bounds.minY), CGPoint(x: bounds.maxX, y: bounds.maxY)])
        shapeLayer.path = path
        layer.addSublayer(shapeLayer)
    }
}

extension Date {
    func dateFormat(withStyle style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func shortFormat() -> String {
        return dateFormat(withStyle: .medium).lowercased()
    }
    
    func timeFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        let mutatedTime = Calendar.current.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0, of: self) ?? self
        return formatter.string(from: mutatedTime)
    }
}

extension Optional where Wrapped == TimeInterval {
    func safelyUnwrapped() -> String {
        guard let self = self else { return "" }
        return "\(self)"
    }
}

extension TimeInterval {
    func timerString(chopped: Bool = true, decimalPlaces: Bool = false) -> String {
        guard !self.isNaN else { return "" }
        let hours = Int(self / (60*60))
        let minutes = Int((self - (Double((hours*60*60)))) / 60)
        
        let deci = (self - (Double((hours*60*60)) + Double((minutes*60))))
        let seconds = Int(deci)
        
        var str = String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        
        if decimalPlaces, self != .zero {
            let miliseconds = Int(deci.truncatingRemainder(dividingBy: max(Double(seconds), 1)) * 10)
            print(miliseconds)
            str.append(String(format: ":%i", miliseconds))
        }
        
        if !chopped { return str }
        
        var chopCount = 0
        if hours == 0 {
            chopCount += 3
        } else if String(hours).count < 2 {
            chopCount += 1
        }
        
        if String(minutes).count == 1 {
            chopCount += 1
        }
        
        str = str.chopPrefix(chopCount)
        
        return str
        
    }
}

extension String {
    func chopPrefix(_ count: Int = 1) -> String {
        if count >= 0 && count <= self.count {
            let indexStartOfText = self.index(self.startIndex, offsetBy: count)
            return String(self[indexStartOfText...])
        }
        return ""
    }

    func chopSuffix(_ count: Int = 1) -> String {
        if count >= 0 && count <= self.count {
            let indexEndOfText = self.index(self.endIndex, offsetBy: -count)
            return String(self[..<indexEndOfText])
        }
        return ""
    }
}

extension UITextView {
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }
    
    override open var intrinsicContentSize: CGSize {
        let textSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        return sizeThatFits(textSize)
    }
}

extension UILabel {
    static func defaultLabel(text: String, font: UIFont = kDefaultFont ?? UIFont.systemFont(ofSize: 15.0), color: UIColor = UIColor.darkGray) -> UILabel {
        return {
            let label = UILabel()
            label.font = font
            label.textAlignment = .center
            label.textColor = color
            label.numberOfLines = 0
            label.text = text
            return label
        }()
    }
}

extension UIView {
    func fix(in container: UIView, padding: UIEdgeInsets = .zero) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.frame = container.frame
        container.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor, constant: padding.top),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding.bottom),
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding.left),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding.right)
        ])
    }
    
    func hfix(in container: UIView, padding: CGFloat = .zero) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.frame = container.frame
        leftAnchor.constraint(equalTo: container.leftAnchor, constant: padding).isActive = true
        rightAnchor.constraint(equalTo: container.rightAnchor, constant: -padding).isActive = true
    }
    
    func vfix(in container: UIView, padding: CGFloat = .zero) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.frame = container.frame
        topAnchor.constraint(equalTo: container.topAnchor, constant: padding).isActive = true
        bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding).isActive = true
    }
    
    func constraintAspectRatio(_ ar: CGFloat, width: CGFloat? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        if let w = width {
            self.widthAnchor.constraint(equalToConstant: w).isActive = true
        }
        
        self.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: ar).isActive = true
    }
    
    func equalLeadingTrailing(to view: UIView, margin: CGFloat = 0.0) {
        leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin).isActive = true
    }
}

extension UIView {
    func findConstraint(layoutAttribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        if let constraints = superview?.constraints {
            for constraint in constraints where itemMatch(constraint: constraint, layoutAttribute: layoutAttribute) {
                return constraint
            }
        }
        return nil
    }
    
    func itemMatch(constraint: NSLayoutConstraint, layoutAttribute: NSLayoutConstraint.Attribute) -> Bool {
        let firstItemMatch = constraint.firstItem as? UIView == self && constraint.firstAttribute == layoutAttribute
        let secondItemMatch = constraint.secondItem as? UIView == self && constraint.secondAttribute == layoutAttribute
        return firstItemMatch || secondItemMatch
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

fileprivate var coverLayerDismisser: (() -> Void)?
extension UIView {
    static var COVERLAYER_TAG: Int { return 80 }
    
    var currentCoverLayer: UIView? {
        return viewWithTag(UIView.COVERLAYER_TAG)
    }
    
    func insertCoverLayer(behind view: UIView, dismissHandler: (() -> Void)? = nil) {
        let layer = UIView(frame: bounds)
        layer.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        layer.alpha = 0.0
        layer.tag = UIView.COVERLAYER_TAG
        layer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(removeCoverLayer)))
        coverLayerDismisser = dismissHandler
        insertSubview(layer, belowSubview: view)
        
        UIView.animate(withDuration: 0.25) {
            layer.alpha = 1.0
        }
    }
    
    @objc func removeCoverLayer(useHandler: Bool = true) {
        coverLayerDismisser?()
        coverLayerDismisser = nil
        if let coverLayer = subviews.first (where: { $0.tag == UIView.COVERLAYER_TAG }) {
            UIView.animate(withDuration: 0.25, animations: {
                coverLayer.alpha = 0.0
            }) { _ in
                coverLayer.removeFromSuperview()
            }
        } else {
            print("No cover layer was found within the views subviews.")
        }
    }
}



