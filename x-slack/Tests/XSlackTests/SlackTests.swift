import XCTest

@testable import XSlack

final class SlackTests: XCTestCase {
  func testJsonEncodeTextSlack() {
    XCTAssertEqual(
      json(.init(text: "foo", channel: "#debug", username: "FLP Bot")),
      """
      {
        "channel" : "#debug",
        "icon_emoji" : "robot_face",
        "text" : "foo",
        "unfurl_links" : false,
        "unfurl_media" : false,
        "username" : "FLP Bot"
      }
      """,
    )
  }

  func testJsonEncodeBlocks() {
    XCTAssertEqual(
      json(.init(
        blocks: [
          .header(text: "foo"),
          .divider,
          .image(url: URL(string: "https://cat.com/cat.png")!, altText: "cat"),
          .section(
            text: "section",
            accessory: .image(
              url: URL(string: "https://cat.com/cat.png")!,
              altText: "cat",
            ),
          ),
        ],
        fallbackText: "a test slack",
        channel: "#debug",
        username: "FLP Bot",
      )),
      """
      {
        "blocks" : [
          {
            "text" : {
              "text" : "foo",
              "type" : "plain_text"
            },
            "type" : "header"
          },
          {
            "type" : "divider"
          },
          {
            "alt_text" : "cat",
            "image_url" : "https:\\/\\/cat.com\\/cat.png",
            "type" : "image"
          },
          {
            "accessory" : {
              "alt_text" : "cat",
              "image_url" : "https:\\/\\/cat.com\\/cat.png",
              "type" : "image"
            },
            "text" : {
              "text" : "section",
              "type" : "mrkdwn"
            },
            "type" : "section"
          }
        ],
        "channel" : "#debug",
        "icon_emoji" : "robot_face",
        "text" : "a test slack",
        "unfurl_links" : false,
        "unfurl_media" : false,
        "username" : "FLP Bot"
      }
      """,
    )
  }
}

private func json(_ msg: Slack.Message) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
  encoder.keyEncodingStrategy = .convertToSnakeCase
  let data = try! encoder.encode(msg)
  return String(data: data, encoding: .utf8)!
}
