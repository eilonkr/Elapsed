//
//  TimerContextModel+CoreDataProperties.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 06/01/2020.
//  Copyright © 2020 Eilon Krauthammer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TimerContextModel)
public class TimerContextModel: NSManagedObject {

}

extension TimerContextModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimerContextModel> {
        return NSFetchRequest<TimerContextModel>(entityName: "TimerContextModel")
    }

    @NSManaged public var activityTitle: String?
    @NSManaged public var isRunning: Bool
    @NSManaged public var lastPauseInterval: Double
    @NSManaged public var startInterval: Double
    @NSManaged public var totalPauseDuration: Double

}
