//
//  ActivityEntryView.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 01/10/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

protocol EntryDelegate: AnyObject {
    func finished(time: TimeInterval)
}

class ActivityEntryView: UIView {
    fileprivate enum Text: Int {
        case hh = 0
        case mm = 1
        case ss = 2
        
        var stringValue: String {
            switch self {
                case .hh: return "hours"
                case .mm: return "minutes"
                case .ss: return "seconds"
            }
        }
    }
    
    private var hhField: UITextField!
    private var mmField: UITextField!
    private var ssField: UITextField!
    
    override var intrinsicContentSize: CGSize {
        CGSize(
            width: bounds.width,
            height: subviews.map {$0.intrinsicContentSize.height}.reduce(0, +)
        )
    }
    
    public weak var delegate: EntryDelegate?

    init(delegate: EntryDelegate?) {
        let width = UIScreen.main.bounds.width * 0.8
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: width*0.5))
        self.delegate = delegate
        setupLayout()
    }
    
    override func layoutSubviews() {
        self.frame.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        setupDesign()
    }
    
    private func setupDesign() {
        backgroundColor = .tertiarySystemBackground
        layer.cornerRadius = 15.0
        layer.applyShadow()
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.5
    }
    
    private func setupLayout() {
        let itemHeight: CGFloat = 36.0
                
        func textField(at index: Int) -> UITextField {
            let tf = UITextField()
            tf.placeholder = Text(rawValue: index)?.stringValue
            tf.font = kDefaultFont?.withSize(15.0)
            tf.keyboardType = .numberPad
            tf.textAlignment = .center
            tf.backgroundColor = .quaternarySystemFill
            tf.layer.cornerRadius = 10.0
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.heightAnchor.constraint(equalToConstant: itemHeight).isActive = true
            
            switch index {
                case 0: hhField = tf
                case 1: mmField = tf
                case 2: ssField = tf
                default: fatalError()
            }
            return tf
        }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 12.0
        
        for i in 0 ..< 3 {
            stackView.addArrangedSubview(textField(at: i))
        }
        
        addSubview(stackView)
        
        let confirm = EKHighlightButton(type: .custom)
        confirm.setTitle("CONFIRM", for: .normal)
        confirm.setTitleColor(UIColor.init(white: 1.0, alpha: 0.9), for: .normal)
        confirm.titleLabel?.font = kDefaultFont?.withSize(17.0)
        confirm.backgroundColor = AppColors.blue
        confirm.layer.cornerRadius = 10.0
        confirm.contentEdgeInsets = .even(8.0)
        confirm.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        addSubview(confirm)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        confirm.translatesAutoresizingMaskIntoConstraints = false
        
        let padding: CGFloat = 12.0
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

            confirm.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: padding),
            confirm.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            confirm.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            //confirm.heightAnchor.constraint(equalToConstant: itemHeight),
            confirm.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
    
    @objc private func confirmTapped() {
        let hours = Int(hhField.text ?? "") ?? 0
        let minutes = Int(mmField.text ?? "") ?? 0
        
        guard let seconds = Int(ssField.text ?? "") else {
            wrongInput()
            return
        }
        
        let timeInterval = (hours*60*60) + (minutes*60) + seconds
        delegate?.finished(time: TimeInterval(timeInterval))
        self.dismiss(cancel: false)
    }
    
    private func wrongInput() {
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
            self.transform = self.transform.translatedBy(x: -30, y: 0)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.2, options: .curveEaseOut, animations: {
                self.transform = .identity
            }, completion: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

// MARK: - Public Actions
extension ActivityEntryView {
    public func appear(in view: UIView) {
        center.x = view.frame.midX
        frame.origin.y = view.safeAreaInsets.top + 100.0
        
        transform = transform.translatedBy(x: 0.0, y: 30.0)
        alpha = 0.0
        view.addSubview(self)
        
        view.insertCoverLayer(behind: self) { [weak self] in
            self?.dismiss()
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.transform = .identity
            self.alpha = 1.0
        }, completion: {_ in
            self.hhField.becomeFirstResponder()
        })
    }
    
    public func dismiss(cancel: Bool = true) {
        if !cancel { superview?.removeCoverLayer() }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.transform = self.transform.translatedBy(x: 0, y: 30)
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
