import Foundation

struct EfficiencyAnalyzer {
    func analyze(output: [OutputEfficiencyPoint]) -> EfficiencyAnalysis {
        let usable = output.filter { $0.productiveHours + $0.sessionHours > 0 }
        let outputPerHour = usable.map(\.outputPerHour).average
        let best = usable.max { $0.outputPerHour < $1.outputPerHour }
        let shortSessions = usable.filter { $0.productiveHours + $0.sessionHours <= 3 }
        let longSessions = usable.filter { $0.productiveHours + $0.sessionHours > 3 }
        let shortEfficiency = shortSessions.map(\.outputPerHour).average
        let longEfficiency = longSessions.map(\.outputPerHour).average
        let advantage = shortEfficiency - longEfficiency

        return EfficiencyAnalysis(
            outputPerHour: outputPerHour,
            bestEfficiencyDay: best?.date,
            shortSessionAdvantage: advantage,
            interpretation: interpretation(outputPerHour: outputPerHour, advantage: advantage)
        )
    }

    private func interpretation(outputPerHour: Double, advantage: Double) -> String {
        if outputPerHour == 0 {
            return "Output correlation needs more learning data."
        }

        if advantage > 0.15 {
            return "Short focused sessions currently produce stronger output density."
        }

        if advantage < -0.15 {
            return "Longer sessions currently produce stronger output density."
        }

        return "Output density is similar across short and long work blocks."
    }
}
