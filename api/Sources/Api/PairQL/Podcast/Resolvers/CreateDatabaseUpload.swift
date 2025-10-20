import Dependencies
import Foundation
import PodcastRoute

extension CreateDatabaseUpload: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let unixTime = Int(Date().timeIntervalSince1970)
    let filename = "\(unixTime)--\(input.installId.uuidString.lowercased()).db"
    let objectName = "podcast-dbs/\(filename)"

    let signedUrl = try with(dependency: \.aws).signedS3UploadUrl(
      objectName,
      contentType: "application/octet-stream",
      isPublicRead: false
    )

    return .init(uploadUrl: signedUrl)
  }
}
