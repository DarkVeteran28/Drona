//
//  ViolationLogger.swift
//  Drona
//
//  Created by Likhith Thejas on 15/05/26.
//

import Foundation
import Combine

class ViolationLogger: ObservableObject {

    @Published var violations: [ViolationEvent] = []

    private let saveURL: URL

    init() {

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        saveURL = documents.appendingPathComponent(
            "violations.json"
        )

        load()
    }

    func log(appName: String) {

        let violation = ViolationEvent(
            timestamp: Date(),
            appName: appName,
            reason: "Distracting app opened"
        )

        violations.append(violation)

        save()
    }

    private func save() {

        do {

            let data = try JSONEncoder().encode(
                violations
            )

            try data.write(to: saveURL)

        } catch {

            print("Failed saving violations")
        }
    }

    private func load() {

        do {

            let data = try Data(contentsOf: saveURL)

            violations = try JSONDecoder().decode(
                [ViolationEvent].self,
                from: data
            )

        } catch {

            violations = []
        }
    }
}
