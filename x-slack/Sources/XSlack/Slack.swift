import Foundation

public enum Slack {}

public extension Slack {
  enum Emoji {
    case fireEngine
    case robotFace
    case books
    case orangeBook
    case custom(String)
  }

  struct Message {
    public enum Content {
      public indirect enum Block {
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
      switch content {
      case .text(let text):
        return text
      case .blocks(_, let fallbackText):
        return fallbackText
      }
    }

    public init(
      text: String,
      channel: String,
      username: String,
      emoji: Emoji = .robotFace
    ) {
      content = .text(text)
      self.channel = channel
      self.emoji = emoji
      self.username = username
    }

    public init(
      blocks: [Content.Block],
      fallbackText: String,
      channel: String,
      username: String,
      emoji: Emoji = .robotFace
    ) {
      content = .blocks(blocks, fallbackText)
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
      return "fire_engine"
    case .robotFace:
      return "robot_face"
    case .books:
      return "books"
    case .orangeBook:
      return "orange_book"
    case .custom(let custom):
      return custom
    }
  }
}

extension Slack.Emoji: Equatable {}
extension Slack.Message: Equatable {}
extension Slack.Message.Content: Equatable {}
extension Slack.Message.Content.Block: Equatable {}
