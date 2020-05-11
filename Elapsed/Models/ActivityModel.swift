//
//  ActivityModel+CoreDataClass.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 20/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ActivityModel)
public class ActivityModel: NSManagedObject {

    convenience init?(activity: Activity) {
        let manager = PersistenceManager.self
        guard let entityDescription =
            NSEntityDescription.entity(forEntityName: manager.Keys.entityName, in: PersistenceManager.shared.context)
            else { return nil }
        self.init(entity: entityDescription, insertInto: PersistenceManager.shared.context)
        
        self.title = activity.title
        self.creationDateRepresentation = activity.creationDateRepresentation
        self.setValue(activity.repeatsData, forKey: manager.Keys.repeats)
    }
    
}

extension ActivityModel {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityModel> {
        return NSFetchRequest<ActivityModel>(entityName: "ActivityModel")
    }
    
    @NSManaged public var title: String?
    @NSManaged public var repeats: Data?
    @NSManaged public var creationDateRepresentation: Double
    
}
