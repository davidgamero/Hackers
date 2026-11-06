import Shared
import SwiftUI
import WidgetKit

private struct TopStoriesEntry: TimelineEntry {
    let date: Date
    let stories: [WidgetTopStory]
    let didFail: Bool

    static let placeholder = TopStoriesEntry(
        date: .now,
        stories: [
            sampleStory(id: 1, title: "A focused read from Hacker News", domain: "example.com", score: 321),
            sampleStory(id: 2, title: "Ask HN: What are you building?", domain: "news.ycombinator.com", score: 188),
            sampleStory(id: 3, title: "A practical guide to a new idea", domain: "example.org", score: 142),
            sampleStory(id: 4, title: "Show HN: A useful open source project", domain: "github.com", score: 97),
            sampleStory(id: 5, title: "Lessons from running systems at scale", domain: "example.net", score: 85),
            sampleStory(id: 6, title: "An unexpected approach that worked", domain: "example.dev", score: 64)
        ],
        didFail: false
    )

    private static func sampleStory(id: Int, title: String, domain: String, score: Int) -> WidgetTopStory {
        WidgetTopStory(
            id: id,
            title: title,
            url: URL(string: "https://\(domain)")!,
            domain: domain,
            score: score,
            commentsCount: max(score / 3, 1)
        )
    }
}

private struct TopStoriesProvider: TimelineProvider {
    private let loader = WidgetTopStoriesLoader()

    func placeholder(in _: Context) -> TopStoriesEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (TopStoriesEntry) -> Void) {
        guard !context.isPreview else {
            completion(.placeholder)
            return
        }
        loadEntry(completion: completion)
    }

    func getTimeline(in _: Context, completion: @escaping @Sendable (Timeline<TopStoriesEntry>) -> Void) {
        loadEntry { entry in
            completion(Timeline(
                entries: [entry],
                policy: .after(Date().addingTimeInterval(30 * 60))
            ))
        }
    }

    private func loadEntry(completion: @escaping @Sendable (TopStoriesEntry) -> Void) {
        Task {
            do {
                let stories = try await loader.load(limit: 8)
                completion(TopStoriesEntry(date: .now, stories: stories, didFail: stories.isEmpty))
            } catch {
                completion(TopStoriesEntry(
                    date: .now,
                    stories: TopStoriesEntry.placeholder.stories,
                    didFail: true
                ))
            }
        }
    }
}

private struct TopStoriesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TopStoriesEntry

    var body: some View {
        Group {
            if family == .systemSmall, let story = entry.stories.first {
                WidgetTopStorySmallContent(story: story)
                    .widgetURL(story.appURL)
            } else {
                WidgetTopStoriesListContent(
                    stories: entry.stories,
                    didFail: entry.didFail,
                    family: family == .systemLarge ? .large : .medium
                )
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct TopStoriesWidget: Widget {
    let kind = "HackersTopStories"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopStoriesProvider()) { entry in
            TopStoriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Hackers Top Stories")
        .description("See top Hacker News stories at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    TopStoriesWidget()
} timeline: {
    TopStoriesEntry.placeholder
}

#Preview(as: .systemSmall) {
    TopStoriesWidget()
} timeline: {
    TopStoriesEntry.placeholder
}

#Preview(as: .systemLarge) {
    TopStoriesWidget()
} timeline: {
    TopStoriesEntry.placeholder
}
