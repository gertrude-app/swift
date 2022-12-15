import Foundation
import NonEmpty

public enum SendGrid {
  public struct EmailAddress: Encodable, ExpressibleByStringLiteral {
    public var email: String
    public var name: String?

    public init(email: String, name: String? = nil) {
      self.email = email
      self.name = name
    }

    public init(stringLiteral email: String) {
      self.email = email
      name = nil
    }
  }

  public struct Email: Encodable {
    public struct Personalization: Encodable {
      public var to: NonEmpty<[EmailAddress]>
    }

    public struct Attachment: Encodable {
      public var type = "text/plain"
      public var filename: String
      public var content: String // base64 encoded

      public init(plainTextContent plainText: String, filename: String) {
        content = plainText.data(using: .utf8)?.base64EncodedString() ?? "<encoding error>"
        self.filename = filename
      }

      public init(base64EncodedTextContent encodedText: String, filename: String) {
        content = encodedText
        self.filename = filename
      }

      public init(data: Data, filename: String) throws {
        content = data.base64EncodedString()
        self.filename = filename
      }
    }

    public struct Content: Encodable {
      public var type: String
      public var value: String
    }

    public var personalizations: NonEmpty<[Personalization]>
    public var from: EmailAddress
    public var replyTo: EmailAddress?
    public var subject: String
    public var content: NonEmpty<[Content]>
    public var attachments: [Attachment]?

    public var firstRecipient: EmailAddress {
      personalizations.first.to.first
    }

    public var text: String {
      content.first.value
    }

    public init(
      to: EmailAddress,
      from: EmailAddress,
      replyTo: EmailAddress? = nil,
      subject: String,
      text: String
    ) {
      personalizations = .init(Personalization(to: .init(to)))
      self.from = from
      self.subject = subject
      self.replyTo = replyTo
      content = .init(Content(type: "text/plain", value: text))
    }

    public init(
      to: EmailAddress,
      from: EmailAddress,
      replyTo: EmailAddress? = nil,
      subject: String,
      html: String
    ) {
      personalizations = .init(Personalization(to: .init(to)))
      self.from = from
      self.subject = subject
      self.replyTo = replyTo
      content = .init(Content(type: "text/html", value: html))
    }
  }
}

extension SendGrid.EmailAddress: Equatable {}
