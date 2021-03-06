//
//  MenuController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 07/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI

class MenuController: UIViewController {
    
    private let actions: KeyValuePairs<String, Selector> = [
        "SETTINGS" : #selector(settings),
        "REPORT A BUG / SUGGEST A FEATURE" : #selector(sendMessage),
        "RATE ON THE APP STORE" : #selector(rate),
        "ABOUT" : #selector(about),
        "DONATE" : #selector(donate)
    ]
    
    private var stack: UIStackView!
    
    private var didLayout = false
    
    override var storyboard: UIStoryboard? {
        UIStoryboard(name: "Main", bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = nil
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissTap)))
        
        setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLayout {
            didLayout = true
            
            stack.arrangedSubviews.forEach { sub in
                UIView.animate(withDuration: 0.3) {
                    sub.transform = .identity
                    sub.alpha = 1.0
                }
            }
        }
    }
    
    private func setupLayout() {
        stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 30.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        actions.map { key, selector in
            let button = UIButton(type: .system)
            button.titleLabel?.font = kDefaultFont!.withSize(20.0)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.setTitleColor(.white, for: .normal)
            button.setTitle(key, for: .normal)
            button.addTarget(self, action: selector, for: .touchUpInside)
            button.transform = .evenScale(1.25)
            button.alpha = 0.0
            return button
        }.forEach {
            stack.addArrangedSubview($0)
        }
        
        view.addSubview(stack)
        stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stack.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8).isActive = true
    }
    
    @objc private func dismissTap() {
        self.dismiss()
    }
    
    @objc private func settings() {
        if let settingsController = storyboard?.instantiateViewController(withIdentifier: "settings") as? UINavigationController {
            self.present(settingsController, animated: true, completion: nil)
        }
        
        dismiss()
    }
    
    private func promptForMessage() {
        let alert = UIAlertController(title: "Enter your message", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Your message"
        }
        
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [unowned self] _ in
            self.promptForMail(withMessage: alert.textFields![0].text ?? "")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func promptForMail(withMessage message: String) {
        if MFMailComposeViewController.canSendMail() {
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject("New Feedback")
            mc.setMessageBody(message, isHTML: false)
            mc.setToRecipients(["eilonkrauthammer@gmail.com"])
            present(mc, animated: true, completion: nil)
        } else {
            print("Cannot send mail!")
        }
    }
    
    // MARK: - Actions
    
    @objc private func about() {
        if let aboutController = storyboard?.instantiateViewController(withIdentifier: "contact") {
            present(aboutController, animated: true, completion: nil)
        }
    }
    
    @objc private func contact() {
    }
    
    @objc private func rate() {
        SKStoreReviewController.requestReview()
    }
    
    @objc private func donate() {
        let alert = UIAlertController(title: "Coming Soon", message: "In the meantime, please feel free to contact me in mail. \n More info in the About section.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func sendMessage() {
        promptForMessage()
    }
    
    deinit {
        print("Menu Gone")
    }
    
}

// MARK: - Presentation

extension MenuController {
    public func present(in vc: UIViewController) {
        vc.addChild(self)
        vc.view.addSubview(view)
        
        vc.view.insertCoverLayer(behind: view)
        
        vc.view.currentCoverLayer?.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        didMove(toParent: vc)
    }
    
    private func dismiss(_ completion: (() -> Void)? = nil) {
        parent?.view.removeCoverLayer()
        UIView.animate(withDuration: 0.3, animations: {
            self.stack.arrangedSubviews.forEach { sub in
                sub.transform = .evenScale(1.25)
                sub.alpha = 0.0
            }
        }) { _ in
            completion?()
            self.willMove(toParent: nil)
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }
}

// MARK: - Mail Handler

extension MenuController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
            case .cancelled: print("Cancelled")
            case .failed, .sent: mailAlert(result)
            default: break
        }
    }
    
    private func mailAlert(_ status: MFMailComposeResult) {
        let alert = UIAlertController(title: status == .sent ? "Success" : "Error occured", message: status == .sent ? "Your message has been submitted successfully!" : "An error has occured while trying to send the message. Please try again", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
