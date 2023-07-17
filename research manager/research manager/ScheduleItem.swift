//
//  ScheduleItem.swift
//  research manager
//
//  Created by 温刚 on 7/16/23.
//

import Foundation

struct ScheduleItem: Identifiable, Codable {
    let id: UUID
    var timeInterval: String
    var courseTitle: String
}
