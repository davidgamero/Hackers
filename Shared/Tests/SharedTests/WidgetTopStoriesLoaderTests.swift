@testable import Shared
import Foundation
import Networking
import Testing

@Suite("Widget top stories loader")
struct WidgetTopStoriesLoaderTests {
    @Test("Loads one front-page response and maps story metadata")
    func loadsFrontPageStories() async throws {
        let network = WidgetNetworkStub(response: """
        {
          "hits": [
            {
              "objectID": "123",
              "title": "A useful story",
              "url": "https://example.com/article",
              "points": 321,
              "num_comments": 45
            },
            {
              "objectID": "124",
              "title": "Ask HN: A self post",
              "url": null,
              "points": 99,
              "num_comments": 80
            }
          ]
        }
        """)
        let loader = WidgetTopStoriesLoader(network: network)

        let stories = try await loader.load(limit: 6)

        #expect(network.requestedURLs.count == 1)
        let components = try #require(URLComponents(url: network.requestedURLs[0], resolvingAgainstBaseURL: false))
        let query: [String: String] = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap {
            guard let value = $0.value else { return nil }
            return ($0.name, value)
        })
        #expect(components.path == "/api/v1/search")
        #expect(query["tags"] == "front_page")
        #expect(query["hitsPerPage"] == "6")
        #expect(stories == [
            WidgetTopStory(
                id: 123,
                title: "A useful story",
                url: URL(string: "https://example.com/article")!,
                domain: "example.com",
                score: 321,
                commentsCount: 45
            ),
            WidgetTopStory(
                id: 124,
                title: "Ask HN: A self post",
                url: URL(string: "https://news.ycombinator.com/item?id=124")!,
                domain: "news.ycombinator.com",
                score: 99,
                commentsCount: 80
            )
        ])
    }

    @Test("Drops malformed hits and respects the requested limit")
    func dropsMalformedHits() async throws {
        let network = WidgetNetworkStub(response: """
        {
          "hits": [
            { "objectID": "bad", "title": "Bad", "points": 1, "num_comments": 0 },
            { "objectID": "1", "title": "One", "points": 3, "num_comments": 1 },
            { "objectID": "2", "title": "Two", "points": 2, "num_comments": 2 }
          ]
        }
        """)

        let stories = try await WidgetTopStoriesLoader(network: network).load(limit: 1)

        #expect(stories.map(\.id) == [1])
    }

    @Test("Invalid server data throws instead of producing an empty successful entry")
    func invalidDataThrows() async {
        let network = WidgetNetworkStub(response: "not-json")

        await #expect(throws: (any Error).self) {
            _ = try await WidgetTopStoriesLoader(network: network).load(limit: 6)
        }
    }
}

@Suite("Widget story layout")
struct WidgetStoryLayoutTests {
    @Test("Medium widget fits three normal text rows without exceeding its row area")
    func mediumFitsThreeRows() {
        let layout = WidgetStoryLayoutPolicy.layout(
            availableHeight: 126,
            family: .medium,
            usesAccessibilityText: false
        )

        #expect(layout.storyCount == 3)
        #expect(layout.rowHeight == 41)
        #expect(layout.requiredHeight == 125)
        #expect(layout.requiredHeight <= 126)
    }

    @Test("Large widget fits six two-line rows and metadata")
    func largeFitsSixDetailedRows() {
        let layout = WidgetStoryLayoutPolicy.layout(
            availableHeight: 300,
            family: .large,
            usesAccessibilityText: false
        )

        #expect(layout.storyCount == 6)
        #expect(layout.requiredHeight <= 300)
    }

    @Test("Medium widget reduces row count when its row area is shorter")
    func constrainedMediumFallsBack() {
        let layout = WidgetStoryLayoutPolicy.layout(
            availableHeight: 83,
            family: .medium,
            usesAccessibilityText: false
        )

        #expect(layout.storyCount == 2)
        #expect(layout.requiredHeight <= 83)
    }

    @Test("Accessibility text uses a taller row budget and cannot overflow")
    func accessibilityRowsFit() {
        let layout = WidgetStoryLayoutPolicy.layout(
            availableHeight: 100,
            family: .medium,
            usesAccessibilityText: true
        )

        #expect(layout.storyCount == 1)
        #expect(layout.requiredHeight <= 100)
    }

    @Test("Small widget always presents one focused story")
    func smallUsesOneStory() {
        let layout = WidgetStoryLayoutPolicy.layout(
            availableHeight: 40,
            family: .small,
            usesAccessibilityText: false
        )

        #expect(layout.storyCount == 1)
        #expect(layout.requiredHeight <= 40)
    }
}

private final class WidgetNetworkStub: NetworkManagerProtocol, @unchecked Sendable {
    let response: String
    var requestedURLs: [URL] = []

    init(response: String) {
        self.response = response
    }

    func get(url: URL) async throws -> String {
        requestedURLs.append(url)
        return response
    }

    func getResponse(url: URL) async throws -> NetworkResponse {
        NetworkResponse(body: try await get(url: url), statusCode: 200, finalURL: url)
    }

    func postResponse(url: URL, body _: String) async throws -> NetworkResponse {
        NetworkResponse(body: "", statusCode: 200, finalURL: url)
    }

    func post(url _: URL, body _: String) async throws -> String { "" }
    func clearCookies() {}
    func containsCookie(for _: URL) -> Bool { false }
    func containsCookie(named _: String, for _: URL) -> Bool { false }
}
