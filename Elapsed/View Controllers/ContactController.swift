//
//  ContactController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 12/05/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import UIKit

class ContactController: UIViewController {

    private lazy var buttonsInfo: [(imageName: String, action: Selector)] = [
        ("icnmail", #selector(mailTapped)),
        ("icntwitter", #selector(twitterTapped)),
        ("icngithub", #selector(githubTapped))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addContactCTAs()
    }
    
    private func addContactCTAs() {
        guard let lastLabel = view.viewWithTag(10) else { return }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 16.0
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: lastLabel.bottomAnchor, constant: 30.0),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        // Generate the buttons
        for info in buttonsInfo {
            let button = EKHighlightButton()
            button.setImage(UIImage(named: info.imageName), for: .normal)
            button.addTarget(self, action: info.action, for: .touchUpInside)
            button.constraintAspectRatio(1/1, width: 52.0)
            button.isOval = true
            button.tintColor = AppColors.blue
            button.backgroundColor = .white
            button.imageEdgeInsets = .even(12.0)
            button.imageView?.contentMode = .scaleAspectFit
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func mailTapped() {
        if let url = URL(string: "mailto:eilonkrauthammer@gmail.com") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @objc private func twitterTapped() {
        if let url = URL(string: "https://twitter.com/mitleyber") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @objc private func githubTapped() {
        if let url = URL(string: "https://github.com/eilonkr") {
            UIApplication.shared.open(url, options: [:])
        }
    }

}
