import Foundation

public enum Slack {}

public extension Slack {
  enum Emoji: Sendable {
    case fireEngine
    case robotFace
    case books
    case orangeBook
    case custom(String)
  }

  struct Message: Sendable {
    public enum Content: Sendable {
      public indirect enum Block: Sendable {
        case header(text: String)
        case image(url: URL, altText: String)
        case section(text: String, accessory: Block?)
        case divider
      }

      case text(String)
      case blocks([Block], String)
    }

    public var content: Content
    public var channel: String
    public var emoji: Emoji
    public var username: String

    public var text: String {
      switch self.content {
      case .text(let text):
        text
      case .blocks(_, let fallbackText):
        fallbackText
      }
    }

    public init(
      text: String,
      channel: String,
      username: String,
      emoji: Emoji = .robotFace,
    ) {
      self.content = .text(text)
      self.channel = channel
      self.emoji = emoji
      self.username = username
    }

    public init(
      blocks: [Content.Block],
      fallbackText: String,
      channel: String,
      username: String,
      emoji: Emoji = .robotFace,
    ) {
      self.content = .blocks(blocks, fallbackText)
      self.channel = channel
      self.emoji = emoji
      self.username = username
    }
  }
}

// extensions

public extension Slack.Message {
  static func link(to url: String, withText text: String) -> String {
    "<\(url)|\(text)>"
  }
}

extension Slack.Emoji: CustomStringConvertible {
  public var description: String {
    switch self {
    case .fireEngine:
      "fire_engine"
    case .robotFace:
      "robot_face"
    case .books:
      "books"
    case .orangeBook:
      "orange_book"
    case .custom(let custom):
      custom
    }
  }
}

extension Slack.Emoji: Equatable {}
extension Slack.Message: Equatable {}
extension Slack.Message.Content: Equatable {}
extension Slack.Message.Content.Block: Equatable {}
