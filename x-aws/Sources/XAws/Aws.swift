import Foundation

public enum AWS {
  public struct Client: Sendable {
    public var signedS3UploadUrl: @Sendable (String) throws -> URL
  }

  public struct Error: Swift.Error, Sendable {
    public let message: String
  }
}

public extension AWS.Client {
  static func live(
    accessKeyId: String,
    secretAccessKey: String,
    endpoint: String,
    bucket: String
  ) -> Self {
    let endpoint = endpoint.replacingOccurrences(of: "https://", with: "")
    return AWS.Client(
      signedS3UploadUrl: { objectKey in
        let signedUrl = AWS.Request.signedUrl(
          httpVerb: .PUT,
          endpoint: endpoint,
          bucket: bucket,
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          objectKey: objectKey,
          expires: 90,
          signedHeaders: [
            "Content-Type": "image/jpeg",
            "x-amz-acl": "public-read",
          ]
        )
        guard let url = URL(string: signedUrl) else {
          throw AWS.Error(message: "Error creating URL")
        }
        return url
      }
    )
  }

  static let mock = AWS.Client(
    signedS3UploadUrl: { _ in URL(string: "/mock-url")! }
  )
}
