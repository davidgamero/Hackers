#if DEBUG
import Shared
import SwiftUI

struct WidgetLayoutFixtureView: View {
    private var stories: [WidgetTopStory] { [
        Self.makeStory(
            id: 91_001,
            title: "A very long Hacker News headline designed to catch medium widget overflow",
            domain: "LONG-EXAMPLE-DOMAIN.COM",
            score: 1_234,
            comments: 987
        ),
        Self.makeStory(
            id: 91_002,
            title: "Another unusually long story title that needs enough context to be useful",
            domain: "NEWS.YCOMBINATOR.COM",
            score: 876,
            comments: 543
        ),
        Self.makeStory(
            id: 91_003,
            title: "Third fixture story remains inside the bottom content margin",
            domain: "EXAMPLE.ORG",
            score: 321,
            comments: 210
        )
    ] }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            WidgetTopStoriesListContent(
                stories: stories,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                didFail: false,
                family: .medium
            )
            .padding(16)
            .frame(width: 338, height: 158)
            .background(Color(.systemBackground), in: .rect(cornerRadius: 22))
            .background {
                Color.clear
                    .accessibilityElement()
                    .accessibilityIdentifier("widget.fixture.medium")
            }
        }
    }

    private static func makeStory(
        id: Int,
        title: String,
        domain: String,
        score: Int,
        comments: Int
    ) -> WidgetTopStory {
        WidgetTopStory(
            id: id,
            title: title,
            url: URL(string: "https://example.com/\(id)")!,
            domain: domain,
            score: score,
            commentsCount: comments
        )
    }
}
#endif
