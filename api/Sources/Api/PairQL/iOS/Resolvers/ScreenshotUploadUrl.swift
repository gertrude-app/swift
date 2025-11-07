import Dependencies
import Foundation
import IOSRoute
import Vapor

extension ScreenshotUploadUrl: Resolver {
  static func resolve(with input: Input, in context: IOSApp.ChildContext) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    @Dependency(\.env) var env
    @Dependency(\.aws) var aws

    let unixTime = Int(now.timeIntervalSince1970)
    let filename = "\(unixTime)--\(uuid().lowercased).jpg"
    let filepath = "\(context.device.id.lowercased)/\(filename)"
    let dir = "\(env.mode == .prod ? "" : "\(env.mode)-")screenshots"
    let objectName = "\(dir)/\(filepath)"
    let webUrlString = "\(env.s3.bucketUrl)/\(objectName)"

    guard URL(string: webUrlString) != nil else {
      throw Abort(.internalServerError, reason: "Unexpected invalid web url")
    }

    let signedUrl = try aws.signedS3UploadUrl(objectName)

    try await context.db.create(Screenshot(
      computerUserId: nil,
      iosDeviceId: context.device.id,
      url: webUrlString,
      width: input.width,
      height: input.height,
      filterSuspended: true, // always true for iOS
      createdAt: input.createdAt,
    ))

    return .init(uploadUrl: signedUrl)
  }
}
