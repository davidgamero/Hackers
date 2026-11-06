import Foundation
import Networking

public struct WidgetTopStory: Equatable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let url: URL
    public let domain: String
    public let score: Int
    public let commentsCount: Int

    public init(
        id: Int,
        title: String,
        url: URL,
        domain: String,
        score: Int,
        commentsCount: Int
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.domain = domain
        self.score = score
        self.commentsCount = commentsCount
    }

    public var appURL: URL {
        URL(string: "com.weiranzhang.Hackers://item?id=\(id)")!
    }
}

public struct WidgetTopStoriesLoader: Sendable {
    private let network: any NetworkManagerProtocol
    private let decoder = JSONDecoder()

    public init(network: any NetworkManagerProtocol = NetworkManager()) {
        self.network = network
    }

    public func load(limit: Int) async throws -> [WidgetTopStory] {
        let requestedLimit = max(limit, 1)
        guard var components = URLComponents(string: "https://hn.algolia.com/api/v1/search") else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "tags", value: "front_page"),
            URLQueryItem(name: "hitsPerPage", value: String(requestedLimit))
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let response = try await network.get(url: url)
        let decoded = try decoder.decode(Response.self, from: Data(response.utf8))
        return Array(decoded.hits.compactMap(makeStory).prefix(requestedLimit))
    }

    private func makeStory(from hit: Hit) -> WidgetTopStory? {
        guard let id = Int(hit.objectID), !hit.title.isEmpty else { return nil }
        let fallbackURL = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        let storyURL = hit.url.flatMap(URL.init(string:)) ?? fallbackURL
        let host = storyURL.host ?? "news.ycombinator.com"
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return WidgetTopStory(
            id: id,
            title: hit.title,
            url: storyURL,
            domain: domain,
            score: hit.points ?? 0,
            commentsCount: hit.commentsCount ?? 0
        )
    }
}

public enum WidgetStoryLayoutFamily: Sendable {
    case small
    case medium
    case large
}

public struct WidgetStoryLayout: Equatable, Sendable {
    public let storyCount: Int
    public let rowHeight: CGFloat
    public let dividerHeight: CGFloat

    public var requiredHeight: CGFloat {
        (CGFloat(storyCount) * rowHeight)
            + (CGFloat(max(storyCount - 1, 0)) * dividerHeight)
    }
}

public enum WidgetStoryLayoutPolicy {
    /// Chooses the densest list that fits the measured row area. The widget gives the
    /// header its intrinsic height first, so this calculation only budgets story rows.
    public static func layout(
        availableHeight: CGFloat,
        family: WidgetStoryLayoutFamily,
        usesAccessibilityText: Bool
    ) -> WidgetStoryLayout {
        let rowHeight: CGFloat = switch (family, usesAccessibilityText) {
        case (.large, true): 64
        case (.large, false): 44
        case (_, true): 52
        case (_, false): 32
        }
        let dividerHeight: CGFloat = 1
        let maximum = switch family {
        case .small: 1
        case .medium: usesAccessibilityText ? 2 : 3
        case .large: usesAccessibilityText ? 4 : 6
        }

        for count in stride(from: maximum, through: 1, by: -1) {
            let candidate = WidgetStoryLayout(
                storyCount: count,
                rowHeight: rowHeight,
                dividerHeight: dividerHeight
            )
            if candidate.requiredHeight <= availableHeight {
                return candidate
            }
        }
        return WidgetStoryLayout(storyCount: 1, rowHeight: rowHeight, dividerHeight: dividerHeight)
    }
}

private extension WidgetTopStoriesLoader {
    struct Response: Decodable {
        let hits: [Hit]
    }

    struct Hit: Decodable {
        let objectID: String
        let title: String
        let url: String?
        let points: Int?
        let commentsCount: Int?

        enum CodingKeys: String, CodingKey {
            case objectID, title, url, points
            case commentsCount = "num_comments"
        }
    }
}
