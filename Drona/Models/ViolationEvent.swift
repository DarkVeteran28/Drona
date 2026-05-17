//
//  ViolationEvent.swift
//  Drona
//
//  Created by Likhith Thejas on 15/05/26.
//

import Foundation

struct ViolationEvent: Codable, Identifiable {

    var id = UUID()

    var timestamp: Date

    var appName: String

    var reason: String
}
