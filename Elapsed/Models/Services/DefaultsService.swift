//
//  DefaultsService.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 09/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import Foundation

struct DefaultsService {
    private struct Keys {
        static let launchCount        = "launch"
        static let displayMiliseconds = "miliseconds"
        static let fullFormat         = "format"
        static let autoResume         = "resume"
        static let spinAnimation      = "spin"
        static let canAskForNotificationApproval = "canAsk"
        static let shouldNotAsk       = "shouldNotAsk"
        static let shouldReceiveNotification = "notification"
    }
    
    static private let defaults = UserDefaults.standard
    
    static var launchCount: Int {
        get { defaults.integer(forKey: Keys.launchCount) }
        set {
            defaults.set(newValue, forKey: Keys.launchCount)
        }
    }
    
    static var canAskForNotificationApproval: Bool {
        get {
            if let value = defaults.object(forKey: Keys.shouldReceiveNotification) as? Bool {
                return value
            }
            return true
        } set {
            defaults.set(newValue, forKey: Keys.canAskForNotificationApproval)
        }
    }
    
    static var shouldNotAskForPermission: Bool {
        get {
            defaults.bool(forKey: Keys.shouldNotAsk)
        } set {
            defaults.set(newValue, forKey: Keys.shouldNotAsk)
        }
    }
    
    static var shouldReceiveNotification: Bool {
        get {

            defaults.bool(forKey: Keys.shouldReceiveNotification)
        } set {
            defaults.set(newValue, forKey: Keys.shouldReceiveNotification)
        }
    }
    
    static var shouldDisplayMiliseconds: Bool {
        get { defaults.bool(forKey: Keys.displayMiliseconds) }
        set {
            defaults.set(newValue, forKey: Keys.displayMiliseconds)
        }
    }
    
    static var shouldShowFullFormat: Bool {
        get { defaults.bool(forKey: Keys.fullFormat) }
        set {
            defaults.set(newValue, forKey: Keys.fullFormat)
        }
    }
    
    static var shouldAutoResumeOnAppStart: Bool {
        get { defaults.bool(forKey: Keys.autoResume) }
        set {
            defaults.set(newValue, forKey: Keys.autoResume)
        }
    }
    
    static var shouldRunSpinAnimation: Bool {
        get {
            if let value = defaults.object(forKey: Keys.spinAnimation) as? Bool {
                return value
            }
            return true
        } set {
            defaults.set(newValue, forKey: Keys.spinAnimation)
        }
    }
    
}
