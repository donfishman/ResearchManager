//
//  Schedule.swift
//  research manager
//
//  Created by 温刚 on 7/16/23.
//

import Foundation

struct Schedule: Identifiable, Codable {
    let id: UUID
    var title: String
    var workDays: [String]
    var timeIntervals: [String]
    var items: [[ScheduleItem]]
}

