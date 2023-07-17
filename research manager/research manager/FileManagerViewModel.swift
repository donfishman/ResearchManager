//
//  FileManagerViewModel.swift
//  research manager
//
//  Created by 温刚 on 7/16/23.
//

import Foundation
import Combine

class FileManagerViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var tabs = [TabData(id: 0, title: "Tab 1", currentDirectory: FileManager.default.homeDirectoryForCurrentUser.path)]
    @Published var newTitle = ""
    @Published var isRenaming = false

    @Published var schedule = Schedule(id: UUID(), title: "My Schedule", workDays: ["周一", "周二", "周三", "周四", "周五"], timeIntervals: ["9:00-10:15", "10:30-11:45", "14:00-15:15", "15:30-16:45"], items: [[ScheduleItem(id: UUID(), timeInterval: "9:00-10:15", courseTitle: "数学"), ScheduleItem(id: UUID(), timeInterval: "10:30-11:45", courseTitle: "英语")], [ScheduleItem(id: UUID(), timeInterval: "9:00-10:15", courseTitle: "物理"), ScheduleItem(id: UUID(), timeInterval: "10:30-11:45", courseTitle: "化学")], [ScheduleItem(id: UUID(), timeInterval: "9:00-10:15", courseTitle: "生物"), ScheduleItem(id: UUID(), timeInterval: "10:30-11:45", courseTitle: "地理")], [ScheduleItem(id: UUID(), timeInterval: "9:00-10:15", courseTitle: "历史"), ScheduleItem(id: UUID(), timeInterval: "10:30-11:45", courseTitle: "政治")], [ScheduleItem(id: UUID(), timeInterval: "9:00-10:15", courseTitle: "体育"), ScheduleItem(id: UUID(), timeInterval: "10:30-11:45", courseTitle: "音乐")]])
    @Published var isEditingSchedule = false
    @Published var newScheduleTitle = ""
    @Published var newWorkDays = [String]()
    @Published var newTimeIntervals = [String]()

    // 文件管理和课程表编辑的相关方法
}

