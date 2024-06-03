extension Slack.Message: Encodable {
  public enum CodingKeys: String, CodingKey {
    case channel
    case iconEmoji
    case text
    case blocks
    case username
    case unfurlLinks
    case unfurlMedia
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(false, forKey: .unfurlLinks)
    try container.encode(false, forKey: .unfurlMedia)
    try container.encode(emoji.description, forKey: .iconEmoji)
    try container.encode(channel, forKey: .channel)
    try container.encode(username, forKey: .username)
    switch content {
    case .text(let text):
      try container.encode(text, forKey: .text)
    case .blocks(let blocks, let text):
      try container.encode(text, forKey: .text)
      try container.encode(blocks, forKey: .blocks)
    }
  }
}

extension Slack.Message.Content.Block: Encodable {
  public enum CodingKeys: String, CodingKey {
    case type, text, imageUrl, altText, accessory
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .header(let text):
      try container.encode("header", forKey: .type)
      try container.encode(TextObject(text, .plainText), forKey: .text)
    case .image(let url, let altText):
      try container.encode("image", forKey: .type)
      try container.encode(url, forKey: .imageUrl)
      try container.encode(altText, forKey: .altText)
    case .divider:
      try container.encode("divider", forKey: .type)
    case .section(let text, let accessory):
      try container.encode("section", forKey: .type)
      try container.encode(TextObject(text), forKey: .text)
      if let accessory = accessory {
        try container.encode(accessory, forKey: .accessory)
      }
    }
  }
}

public struct TextObject: Encodable {
  public enum TextType: Equatable {
    case plainText
    case markdown
  }

  public let type: String
  public let text: String

  public init(_ text: String, _ textType: TextType = .markdown) {
    self.type = textType == .markdown ? "mrkdwn" : "plain_text"
    self.text = text
  }
}
