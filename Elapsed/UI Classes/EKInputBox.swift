//
//  EKInputBox.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 21/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

@objc protocol InputBoxDelegate: AnyObject {
    @objc optional func textDidChange(_ text: String)
    @objc optional func didStartEditing()
    @objc optional func didEndEditing()
}

class EKInputBox: UIView {
    
    private let commonWhite = UIColor(white: 1.0, alpha: 0.4)

    @IBOutlet weak var contentView: UIView!
    
    internal lazy var highlightView: UIView = {
        let view = UIView(frame: bounds)
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
        view.alpha = 0.0
        addSubview(view)
        return view
    }()
    
    @IBOutlet private weak var signImageView: UIImageView!
    @IBOutlet private weak var textField: UITextField!
    
    public weak var delegate: InputBoxDelegate?
    
    public var input: String {
        get {
            return textField.text ?? ""
        } set {
            textField.text = newValue
        }
    }
    
    @IBInspectable public var sign: UIImage = UIImage(named: "pencil") ?? UIImage()
    @IBInspectable public var placeholder: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = nil
        Bundle.main.loadNibNamed(String(describing: EKInputBox.self), owner: self, options: nil)
        contentView.fix(in: self)
        clipsToBounds = true
        
        signImageView.contentMode = .scaleAspectFit
        signImageView.tintColor = commonWhite
        signImageView.image = sign
        
        setupTextField()
    }
    
    private func setupTextField() {
        textField.delegate = self
        textField.placeholder = placeholder ?? textField.placeholder
        
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "", attributes: [
            NSAttributedString.Key.foregroundColor : commonWhite
        ])
        textField.tintColor = commonWhite
        textField.returnKeyType = .done
    }
    
    private func selectText() {
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.15) {
            self.highlightView.alpha = 1.0
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.15) {
            self.highlightView.alpha = 0.0
        }
        
        guard let touch = touches.first else { return }
        guard bounds.contains(touch.location(in: self)) else { return }
        self.textField.isUserInteractionEnabled = true
        self.textField.becomeFirstResponder()
        selectText()
    }
    
}

extension EKInputBox: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        delegate?.textDidChange?(updatedString)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.didStartEditing?()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didEndEditing?()
        textField.isUserInteractionEnabled = false
    }
    
}







