//
//  TimerService.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 05/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//

import UIKit
import CoreData

class TimerContext {

    private let entityName = String(describing: TimerContextModel.self)
    
    static private(set) var shared = TimerContext()
    
    // MARK: - Core Data
    
    public var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    public private(set) var timerManagedObject: TimerContextModel?
    public private(set) var isActive: Bool = false
    
    private func save() {
        do {
            try context.save()
        } catch let error {
            print(error.localizedDescription)
        }
    }
      
    // MARK: - Initializers
    
    private init?() {
        let fetchRequest: NSFetchRequest<TimerContextModel> = TimerContextModel.fetchRequest()
        if let result = try? context.fetch(fetchRequest).first {
            self.timerManagedObject = result
            self.isActive = true
        } else {
            return nil
        }
    }
    
    public init(activityTitle: String) {
        let fetchRequest: NSFetchRequest<TimerContextModel> = TimerContextModel.fetchRequest()
        let predicate = NSPredicate(format: "activityTitle = %@", activityTitle)
        fetchRequest.predicate = predicate
        if let result = try? context.fetch(fetchRequest).first {
            self.timerManagedObject = result
            self.isActive = true
        } else {
            guard let entityDescription =
                NSEntityDescription.entity(forEntityName: entityName, in: context) else { return }
            self.timerManagedObject = TimerContextModel(entity: entityDescription, insertInto: context)
            
            self.activityTitle = activityTitle
        }
    }
        
    private var nowInterval: Double { Date().timeIntervalSince1970 }
    
    // MARK: - Computed properties & functions
    
    public var activityTitle: String? {
        get { timerManagedObject?.activityTitle }
        set {
            timerManagedObject?.activityTitle = newValue
            save()
        }
    }
    
    private var lastPauseInterval: Double? {
        get {
            let val = (timerManagedObject?.lastPauseInterval ?? 0)
            return val == 0 ? nil : val
        } set {
            timerManagedObject?.lastPauseInterval = newValue ?? 0
            save()
        }
    }

    private var totalPauseDuration: TimeInterval {
        get {
            timerManagedObject?.totalPauseDuration ?? 0
        } set {
            timerManagedObject?.totalPauseDuration = newValue
            save()
        }
    }
    
    private var startInterval: Double? {
        get {
            let val = (timerManagedObject?.startInterval ?? 0)
            return val == 0 ? nil : val
        }
    }
    
    public var isRunning: Bool {
        get { timerManagedObject?.isRunning ?? false }
    }
    
    public func setTimerBegin() {
        timerManagedObject?.startInterval = nowInterval
        setTimerRunning(true)
    }
    
    public func setTimerEnd() {
        setTimerRunning(false)
        reset()
    }
    
    public func setTimerRunning(_ flag: Bool) {
        timerManagedObject?.isRunning = flag
        save()
    }
    
    public func setPause() {
        timerManagedObject?.lastPauseInterval = nowInterval
        save()
    }
    
    public func setResume() {
        totalPauseDuration += nowInterval - (lastPauseInterval ?? nowInterval)
        lastPauseInterval = nil
    }
    
    private func reset() {
        guard let managedObject = timerManagedObject else { return }
        context.delete(managedObject)
        Self.shared = nil
    }
    
    public var elapsed: TimeInterval? {
        if let interval = startInterval {
            let absoluteElapsed = nowInterval - interval
            let pauseDuration = nowInterval - (lastPauseInterval ?? nowInterval)
            return absoluteElapsed - (totalPauseDuration + pauseDuration)
        }
        
        return .none
    }
}



