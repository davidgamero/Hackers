import SwiftUI

public struct WidgetTopStoriesListContent: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let stories: [WidgetTopStory]
    private let didFail: Bool
    private let family: WidgetStoryLayoutFamily

    public init(
        stories: [WidgetTopStory],
        didFail: Bool,
        family: WidgetStoryLayoutFamily
    ) {
        self.stories = stories
        self.didFail = didFail
        self.family = family
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
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
                if didFail {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(2)
                        .accessibilityLabel("Showing sample stories because refresh failed")
                }
            }
        }
    }

    private func storyRow(_ story: WidgetTopStory) -> some View {
        Group {
            if family == .medium {
                Text(story.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                detailedStoryRow(story)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private func detailedStoryRow(_ story: WidgetTopStory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(story.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
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
            Text(story.title)
                .font(.headline)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 5)
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
