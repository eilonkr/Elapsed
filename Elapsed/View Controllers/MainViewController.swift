//
//  MainViewController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 16/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit
import CoreData
import Hero

class MainViewController: UIViewController {
    
    private let cellIdentifier = "Cell"
    private let maxRecentActivities = 2

    @IBOutlet weak var quickstartTableView: UITableView!
    @IBOutlet weak var timerView: TimerView!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var titleInputBox: EKInputBox!
    
    private var allActivities: [Activity] {
        PersistenceManager.shared.allActivities
    }
    
    private var didLayout = false
    
    private var appDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        generalSetup()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        quickstartTableView.reloadData()
        view.layoutIfNeeded()
        
        // Request notification approval
        
        appDelegate.allowsNotifications { [unowned self] allows in
            if !allows && self.appDelegate.canAsk {
                self.requestNotificationApproval()
            }
        }
        
        if TimerContext.shared?.isActive ?? false {
            self.timerViewDidStart(self.timerView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLayout {
            didLayout = true
        }
    }
    
    private func setupTableView() {
        quickstartTableView.estimatedRowHeight = 50
        quickstartTableView.rowHeight = UITableView.automaticDimension
        quickstartTableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 0, height: 1))
        quickstartTableView.separatorStyle = .none
    }
    
    private func generalSetup() {
        view.layer.applyGradient(ofColors: [AppColors.background1, AppColors.background2])
        timerView.tag = 1
        timerView.delegate = self
        titleInputBox.delegate = self
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        MenuController().present(in: self)
    }
    
    private func requestNotificationApproval() {
        let alert = UIAlertController(title: "Allow Notifications", message: "Hey there! Allow Elapsed to send you notifications to let you know when you have timers running in the background. You can change this later in settings.", preferredStyle: .alert)
        let approve = UIAlertAction(title: "Sure!", style: .default) { [unowned self] _ in
            self.appDelegate.requestNotificationPermission()
        }
        let notNow = UIAlertAction(title: "Not Now", style: .default) { _ in
            DefaultsService.canAskForNotificationApproval = false
        }
        let dontAskAgain = UIAlertAction(title: "No and don't ask me again", style: .destructive) { _ in
            DefaultsService.shouldNotAskForPermission = true
        }
        
        alert.addAction(approve)
        alert.addAction(notNow)
        alert.addAction(dontAskAgain)
        
        present(alert, animated: true, completion: nil)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(maxRecentActivities, allActivities.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? QuickstartCell
            else { fatalError() }
        cell.selectionStyle = .none
        cell.isLast = indexPath.row == tableView.numberOfRows(inSection: 0) - 1
        
        let activity = allActivities[indexPath.row]
        cell.configure(with: activity)
        
        cell.onStart = { [weak self] title in
            guard let self = self else { return }
            self.titleInputBox.input = title
            self.timerViewDidStart(self.timerView)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension MainViewController: TimerDelegate, InputBoxDelegate, DropdownDelegate {
    func timerViewDidStart(_ timerView: TimerView) {
        // Transition to new controller
        if let timerVc = storyboard?.instantiateViewController(withIdentifier: "Timer") as? TimerController {
            timerVc.modalPresentationStyle = .custom
            timerVc.hero.modalAnimationType = .auto
            timerVc.startDateRepresentation = Date().timeIntervalSince1970
            timerVc.activityTitle = self.titleInputBox.input
            timerVc.allActivities = self.allActivities
            timerVc.onFinish = { [weak self] in
                self?.quickstartTableView.reloadData()
            }
            
            present(timerVc, animated: true, completion: nil)
        }
    }
    
    func didStartEditing() {
        modifiyForSearch(sign: true)
    }
    
    func didEndEditing() {
        modifiyForSearch(sign: false)
    }
    
    private func modifiyForSearch(sign: Bool) {
        print("Whyyy")
        let existing = view.subviews.first {$0 is EKDropdown} as? EKDropdown
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.titleInputBox.transform = sign ? .init(translationX: 0, y: -200) : .identity
            for sub in self.view.subviews where sub !== self.titleInputBox {
                sub.alpha = sign ? 0.0 : 1.0
            }
            existing?.frame.origin.y = self.titleInputBox.frame.maxY + 8.0
            existing?.dismiss()
        }) { _ in
            guard sign else { return }
            let dropdown = EKDropdown(frame: CGRect(
                x: self.titleInputBox.frame.minX,
                y: self.titleInputBox.frame.maxY + 8.0,
                width: self.titleInputBox.frame.width, height: 1),
                                      options: self.allActivities.map {$0.title},
                                      delegate: self)
            self.view.addSubview(dropdown)
        }
    
    }
    
    func dropdown(_ dropdown: EKDropdown, didSelect option: String) {
        self.titleInputBox.input = option
        self.view.endEditing(true)
    }
    
}










