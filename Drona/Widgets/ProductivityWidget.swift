import WidgetKit
import SwiftUI

struct ProductivityEntry:
    TimelineEntry {

    let date: Date

    let summary: WidgetSummary
}

struct Provider:
    TimelineProvider {

    func placeholder(
        in context: Context
    ) -> ProductivityEntry {

        ProductivityEntry(
            date: Date(),
            summary: WidgetSummary(
                productiveHours: 4.2,
                distractingHours: 1.0,
                productivityScore: 81,
                status: "winning",
                streak: 5,
                goalProgress: 0.72
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion:
            @escaping (
                ProductivityEntry
            ) -> Void
    ) {

        let summary =
            SharedDataProvider.shared
                .loadSummary()

        completion(
            ProductivityEntry(
                date: Date(),
                summary:
                    summary ??
                    WidgetSummary(
                        productiveHours: 0,
                        distractingHours: 0,
                        productivityScore: 0,
                        status: "unknown",
                        streak: 0,
                        goalProgress: 0
                    )
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion:
            @escaping (
                Timeline<ProductivityEntry>
            ) -> Void
    ) {

        let summary =
            SharedDataProvider.shared
                .loadSummary()

        let entry =
            ProductivityEntry(
                date: Date(),
                summary:
                    summary ??
                    WidgetSummary(
                        productiveHours: 0,
                        distractingHours: 0,
                        productivityScore: 0,
                        status: "unknown",
                        streak: 0,
                        goalProgress: 0
                    )
            )

        let timeline =
            Timeline(
                entries: [entry],
                policy: .after(
                    Date()
                        .addingTimeInterval(300)
                )
            )

        completion(timeline)
    }
}

struct ProductivityWidgetView:
    View {

    var entry: Provider.Entry

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Drona")
                .font(.headline)

            Text(
                String(
                    format:
                        "Code: %.1fh",
                    entry.summary
                        .productiveHours
                )
            )

            Text(
                String(
                    format:
                        "Waste: %.1fh",
                    entry.summary
                        .distractingHours
                )
            )

            Text(
                String(
                    format:
                        "Score: %.0f%%",
                    entry.summary
                        .productivityScore
                )
            )
        }
        .padding()
    }
}

struct ProductivityWidget:
    Widget {

    let kind =
        "ProductivityWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in

            ProductivityWidgetView(
                entry: entry
            )
        }
        .configurationDisplayName(
            "Drona Productivity"
        )
        .description(
            "Live productivity overview."
        )
        .supportedFamilies([
            .systemSmall
        ])
    }
}
