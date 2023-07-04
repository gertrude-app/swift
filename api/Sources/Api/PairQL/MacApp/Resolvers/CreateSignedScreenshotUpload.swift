import Foundation
import MacAppRoute
import Vapor

extension CreateSignedScreenshotUpload: Resolver {
  static func resolve(with input: Input, in context: UserContext) async throws -> Output {
    let device = try await context.device()
    let unixTime = Int(Date().timeIntervalSince1970)
    let filename = "\(unixTime)--\(Current.uuid().lowercased).jpg"
    let filepath = "\(device.id.lowercased)/\(filename)"
    let dir = "\(Env.mode == .prod ? "" : "\(Env.mode)-")screenshots"
    let objectName = "\(dir)/\(filepath)"
    let webUrlString = "\(Env.CLOUD_STORAGE_BUCKET_URL)/\(objectName)"

    guard let webUrl = URL(string: webUrlString) else {
      throw Abort(
        .internalServerError,
        reason: "Unexpected nil constructing signed upload url"
      )
    }

    let signedUrl = try Current.aws.signedS3UploadUrl(objectName)

    try await Current.db.create(Screenshot(
      deviceId: device.id,
      url: webUrlString,
      width: input.width,
      height: input.height,
      createdAt: input.createdAt ?? Date()
    ))

    return .init(uploadUrl: signedUrl, webUrl: webUrl)
  }
}
