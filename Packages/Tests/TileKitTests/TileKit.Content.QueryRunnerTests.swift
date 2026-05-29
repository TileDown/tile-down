import Testing
@testable import TileKit

@Suite("Content query runner")
struct ContentQueryRunnerTests {
    @Test("filters orders and slices records")
    func filtersOrdersAndSlicesRecords() {
        let runner = TileKit.Content.QueryRunner()
        let result = runner.run(
            .init(
                contentType: "post",
                filter: .all(
                    [
                        .field("published", .equals, true),
                        .field("priority", .greaterThan, 1),
                    ],
                ),
                order: [
                    .init(
                        key: "priority",
                        direction: .descending,
                    ),
                ],
                limit: 2,
            ),
            records: publishingRecords(),
        )

        #expect(result.map(\.id) == ["post-c", "post-a"])
    }

    @Test("matches string and list fields")
    func matchesStringAndListFields() {
        let runner = TileKit.Content.QueryRunner()
        let result = runner.run(
            .init(
                filter: .all(
                    [
                        .field("summary", .caseInsensitiveLike, "SERVICE"),
                        .field("tags", .matchesAny, ["tiles", "forms"]),
                    ],
                ),
            ),
            records: serviceRecords(),
        )

        #expect(result.map(\.id) == ["tile-functions"])
    }

    private func publishingRecords() -> [TileKit.Content.Record] {
        [
            record(
                "post-a",
                fields: [
                    "published": true,
                    "priority": 2,
                    "title": "Alpha",
                ],
            ),
            record(
                "post-b",
                fields: [
                    "published": false,
                    "priority": 4,
                    "title": "Beta",
                ],
            ),
            record(
                "post-c",
                fields: [
                    "published": true,
                    "priority": 3,
                    "title": "Gamma",
                ],
            ),
            record(
                "note-a",
                contentType: "note",
                fields: [
                    "published": true,
                    "priority": 5,
                    "title": "Note",
                ],
            ),
        ]
    }

    private func serviceRecords() -> [TileKit.Content.Record] {
        [
            record(
                "tile-functions",
                fields: [
                    "summary": "Service-backed tile functions",
                    "tags": ["swift", "tiles", "services"],
                ],
            ),
            record(
                "static-pages",
                fields: [
                    "summary": "Static page rendering",
                    "tags": ["html", "templates"],
                ],
            ),
        ]
    }

    private func record(
        _ id: String,
        contentType: String = "post",
        fields: [String: TileKit.Content.FieldValue],
    ) -> TileKit.Content.Record {
        .init(
            id: id,
            contentType: contentType,
            fields: fields,
        )
    }
}
