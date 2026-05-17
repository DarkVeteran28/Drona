//
//  AppUsage.swift
//  Drona
//
//  Created by Likhith Thejas on 15/05/26.
//

import Foundation

struct AppUsage: Codable, Identifiable {

    var id = UUID()

    var appName: String
    var bundleIdentifier: String?

    var totalTime: TimeInterval

    var lastActive: Date
}
