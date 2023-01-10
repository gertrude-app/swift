import Foundation
import SotoS3

struct AWS {
  var signedS3UploadURL: (URL) async throws -> URL
  var deleteScreenshots: ([String]) async throws -> Bool
}

// extensions

extension AWS {
  static func live(s3: S3) -> AWS {
    AWS(
      signedS3UploadURL: { destination in
        try await s3.signURL(
          url: destination,
          httpMethod: .PUT,
          headers: ["Content-Type": "image/jpeg", "x-amz-acl": "public-read"],
          expires: .seconds(90)
        ).get()
      },
      deleteScreenshots: { urls in
        let objects = urls.map { url in
          S3.ObjectIdentifier(
            key: url.replacingOccurrences(
              of: Env.CLOUD_STORAGE_BUCKET_URL + "/",
              with: ""
            )
          )
        }
        let input = S3.DeleteObjectsRequest(
          bucket: Env.CLOUD_STORAGE_BUCKET,
          delete: S3.Delete(objects: objects)
        )
        let result = try await s3.deleteObjects(input).get()
        return result.errors == nil && result.deleted?.count == urls.count
      }
    )
  }
}

extension AWS {
  static let mock = AWS(
    signedS3UploadURL: { _ in .init(string: "https://not-real.com")! },
    deleteScreenshots: { _ in true }
  )
}
