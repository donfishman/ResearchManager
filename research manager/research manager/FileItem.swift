//
//  FileItem.swift
//  research manager
//
//  Created by 温刚 on 7/16/23.
//

import Foundation

struct FileItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var path: String
    var isDirectory: Bool
}

