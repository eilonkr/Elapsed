//
//  Activity.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

// MARK: - Repeat
struct Repeat: Equatable, Codable {
    let date: Date, time: TimeInterval
    var formatted: String { time.timerString() }
    
    static func new(_ interval: TimeInterval) -> Repeat {
        return Repeat(date: Date(), time: interval)
    }
    
    func chartRepresentation(floor: CGFloat, ceil: CGFloat) -> CGFloat {
        guard ceil > floor else { return 1.0 }
        return (CGFloat(time) - floor) / (ceil - floor)
    }
}

// MARK: - Activity
struct Activity: Equatable {
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.title == rhs.title
    }
    
    // MARK: - Properties
    
    var title: String
    let creationDateRepresentation: TimeInterval
    var repeats: [Repeat] = [Repeat]()
    
    // MARK: - Computed properties
    
    public var lastRepeat: Repeat? {
        return dateSortedRepeats.first
    }
    
    public var average: TimeInterval? {
        return repeats.map {$0.time}.reduce(0, +) / Double(repeats.count)
    }
    
    public var shortest: TimeInterval? {
        return repeats.map {$0.time}.min()
    }
    
    public var longest: TimeInterval? {
        return repeats.map {$0.time}.max()
    }
    
    public var dateSortedRepeats: [Repeat] {
        return repeats.sorted { $0.date > $1.date }
    }
    
    // MARK: - Initializers & Coding
    
    init(title: String, creationDate: TimeInterval, repeats: [Repeat]?) {
        self.title = title
        self.creationDateRepresentation = creationDate
        self.repeats = repeats ?? []
        self.repeats.sort { $0.date < $1.date }
    }
     
    init?(fromModel model: ActivityModel) {
        guard
            let title = model.title,
            let repeatsData = model.repeats,
            let repeats = try? JSONDecoder().decode([Repeat].self, from: repeatsData) as [Repeat]
        else { return nil }
        let creationDate = model.creationDateRepresentation
        
        self.title = title
        self.creationDateRepresentation = creationDate
        self.repeats = repeats
    }
    
    public var repeatsData: Data? {
        return try? JSONEncoder().encode(self.repeats)
    }
    
    // MARK: - Functions
    
    static func exists(_ title: String) -> Bool {
        return PersistenceManager.shared.allActivities.contains { $0.title == title }
    }
    
    mutating func addRepeat(_ _repeat: Repeat) {
        repeats.append(_repeat)
    }
    
    mutating func removeRepeat(_ _repeat: Repeat) {
        repeats.removeAll {$0 == _repeat}
    }
    
    mutating func rename(to title: String) {
        try? PersistenceManager.shared.saveActivity(self, newTitle: title)
        self.title = title
    }
    
    func delete() {
        PersistenceManager.shared.deleteActivity(self)
    }
    
}






