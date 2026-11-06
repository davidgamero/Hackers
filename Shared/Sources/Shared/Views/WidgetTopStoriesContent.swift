import SwiftUI

public struct WidgetTopStoriesListContent: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let stories: [WidgetTopStory]
    private let date: Date
    private let didFail: Bool
    private let family: WidgetStoryLayoutFamily

    public init(
        stories: [WidgetTopStory],
        date: Date,
        didFail: Bool,
        family: WidgetStoryLayoutFamily
    ) {
        self.stories = stories
        self.date = date
        self.didFail = didFail
        self.family = family
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            GeometryReader { proxy in
                let layout = WidgetStoryLayoutPolicy.layout(
                    availableHeight: proxy.size.height,
                    family: family,
                    usesAccessibilityText: dynamicTypeSize.isAccessibilitySize
                )
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(stories.prefix(layout.storyCount).enumerated()), id: \.element.id) { index, story in
                        if index > 0 {
                            Divider().frame(height: layout.dividerHeight)
                        }
                        Link(destination: story.appURL) {
                            storyRow(story)
                                .frame(height: layout.rowHeight)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("widget.story.\(story.id)")
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "newspaper.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
            Text("Top Stories")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if didFail {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Showing sample stories because refresh failed")
            } else {
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 6)
        .accessibilityIdentifier("widget.header")
    }

    private func storyRow(_ story: WidgetTopStory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(story.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            HStack(spacing: 5) {
                Text(story.domain.uppercased())
                    .lineLimit(1)
                Spacer(minLength: 4)
                Label("\(story.score)", systemImage: "arrow.up")
                Label("\(story.commentsCount)", systemImage: "message")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

public struct WidgetTopStorySmallContent: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let story: WidgetTopStory

    public init(story: WidgetTopStory) {
        self.story = story
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(.orange)
                Text("Top Story")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            Text(story.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 4)
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                Text(story.domain.uppercased())
                    .lineLimit(1)
                Spacer(minLength: 2)
                Label("\(story.score)", systemImage: "arrow.up")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
