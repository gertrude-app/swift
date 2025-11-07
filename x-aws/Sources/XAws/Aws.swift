import Foundation

public enum AWS {
  public struct Client: Sendable {
    public var _signedS3UploadUrl: @Sendable (String, String, Bool) throws -> URL

    public init(signedS3UploadUrl: @Sendable @escaping (String, String, Bool) throws -> URL) {
      self._signedS3UploadUrl = signedS3UploadUrl
    }
  }

  public struct Error: Swift.Error, Sendable {
    public let message: String
  }
}

public extension AWS.Client {
  func signedS3UploadUrl(
    _ objectKey: String,
    contentType: String = "image/jpeg",
    isPublicRead: Bool = true,
  ) throws -> URL {
    try self._signedS3UploadUrl(objectKey, contentType, isPublicRead)
  }
}

public extension AWS.Client {
  static func live(
    accessKeyId: String,
    secretAccessKey: String,
    endpoint: String,
    bucket: String,
  ) -> Self {
    let endpoint = endpoint.replacingOccurrences(of: "https://", with: "")
    return AWS.Client(
      signedS3UploadUrl: { objectKey, contentType, isPublicRead in
        var signedHeaders: [String: String] = [
          "Content-Type": contentType,
        ]
        if isPublicRead {
          signedHeaders["x-amz-acl"] = "public-read"
        }
        let signedUrl = AWS.Request.signedUrl(
          httpVerb: .PUT,
          endpoint: endpoint,
          bucket: bucket,
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          objectKey: objectKey,
          expires: 90,
          signedHeaders: signedHeaders,
        )
        guard let url = URL(string: signedUrl) else {
          throw AWS.Error(message: "Error creating URL")
        }
        return url
      },
    )
  }

  static let mock = AWS.Client(
    signedS3UploadUrl: { _, _, _ in URL(string: "/mock-url")! },
  )
}
