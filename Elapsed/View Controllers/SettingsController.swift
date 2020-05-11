//
//  SettingsController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 09/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import UIKit

class SettingsController: UITableViewController {
    
    @IBOutlet weak var shouldShowMilisecondsSwitch: UISwitch!
    @IBOutlet weak var shouldShowFullFormatSwitch: UISwitch!
    @IBOutlet weak var shouldAnimateSpinSwitch: UISwitch!
    @IBOutlet weak var shouldAutoResumeSwitch: UISwitch!
    @IBOutlet weak var shouldReceiveNotificationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shouldShowMilisecondsSwitch.isOn     = DefaultsService.shouldDisplayMiliseconds
        shouldShowFullFormatSwitch.isOn      = DefaultsService.shouldShowFullFormat
        shouldAnimateSpinSwitch.isOn         = DefaultsService.shouldRunSpinAnimation
        shouldAutoResumeSwitch.isOn          = DefaultsService.shouldAutoResumeOnAppStart
        shouldReceiveNotificationSwitch.isOn = DefaultsService.shouldReceiveNotification
    }

    @IBAction func showMilisecondsSwitched(_ sender: UISwitch) {
        DefaultsService.shouldDisplayMiliseconds = sender.isOn
    }
    
    @IBAction func showFullFormatSwitched(_ sender: UISwitch) {
        DefaultsService.shouldShowFullFormat = sender.isOn
    }
    
    @IBAction func runSpinAnimationTapped(_ sender: UISwitch) {
        DefaultsService.shouldRunSpinAnimation = sender.isOn
    }
    
    @IBAction func autoresumeSwitched(_ sender: UISwitch) {
        DefaultsService.shouldAutoResumeOnAppStart = sender.isOn
    }
    
    @IBAction func shouldReceiveNotificationSwitched(_ sender: Any) {
        
    }
    
}
