//
//  TabData.swift
//  research manager
//
//  Created by 温刚 on 7/16/23.
//

import Foundation

struct TabData: Identifiable, Codable {
    let id: Int
    var title: String
    var currentDirectory: String
}

