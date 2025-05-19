import ConcurrencyExtras
import Dependencies
import DependenciesMacros
import Foundation
import os.log
import XCore

@DependencyClient
public struct RecorderClient: Sendable {
  public var ensureScreenshotsDir: @Sendable () -> Bool = { true }
  public var saveScreenshotForUpload: @Sendable (UploadScreenshotData) -> Bool = { _ in true }
  public var startUploadTask: @Sendable () -> Task<Void, Never> = { Task {} }
}

extension RecorderClient: DependencyKey {
  public static var liveValue: RecorderClient {
    .init(
      ensureScreenshotsDir: {
        let fm = FileManager.default
        guard let screenshotsDir = URL.screenshotsDir else {
          return false
        }
        if !fm.fileExists(atPath: screenshotsDir.path) {
          do {
            try fm.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
            return true
          } catch {
            return false
          }
        }
        return true
      },
      saveScreenshotForUpload: { img in
        guard let screenshotsDir = URL.screenshotsDir else {
          return false
        }

        let metaData = ScreenshotMetaData(
          width: img.width,
          height: img.height,
          createdAt: img.createdAt
        )
        let filename = metaData.filename
        os_log("[G•] storing screenshot to disk for later upload: %{public}s", filename)

        do {
          try img.data.write(to: screenshotsDir.appendingPathComponent(filename))
        } catch {
          return false
        }

        @Dependency(\.storage) var storage
        storage.saveCodable(value: metaData, forKey: filename)
        return true
      },
      startUploadTask: {
        Task {
          @Dependency(\.suspendingClock) var clock
          @Dependency(\.storage) var storage
          @Dependency(\.api) var api
          let connection = storage.loadConnection()
          if let token = connection?.token {
            await api.setAuthToken(token)
          }
          var count = 0
          // Using this approach so that the recording process promptly has
          // one last chance to upload after recording is completed.
          while !Task.isCancelled {
            count += 1
            if count == 40 { // Every ~20 seconds
              await uploadAvailableScreenshots(api, clock)
              count = 0
            }
            do {
              try await clock.sleep(for: .seconds(0.5))
            } catch {
              break
            }
          }
          Task.detached {
            await uploadAvailableScreenshots(api, clock) // Final upload.
          }
        }
      }
    )
  }
}

@Sendable
private func uploadAvailableScreenshots(_ api: ApiClient, _ clock: any Clock<Duration>) async {
  while let s = getNextUnprocessedScreenshot() {
    do {
      try await api.uploadScreenshot(s.image)
      s.cleanup()
      // prevent filesystem from seeing the same cleaned up file
      try? await clock.sleep(for: .milliseconds(5))
    } catch {
      os_log("[G•] Failed to upload screenshot: %{public}@", error.localizedDescription)
      break // Will try again on the next 20s interval.
    }
  }
}

@Sendable
private func getNextUnprocessedScreenshot(depth: Int = 0)
  -> (image: UploadScreenshotData, cleanup: () -> Void)? {
  guard let screenshotsDir = URL.screenshotsDir, depth < 50 else {
    return nil
  }

  let fm = FileManager.default

  var files: [URL]
  do {
    files = try fm.contentsOfDirectory(at: screenshotsDir, includingPropertiesForKeys: nil)
  } catch {
    os_log("[G•] Failed to get contents of screenshots dir: %{public}s", "\(error)")
    return nil
  }

  files.sort { $0.lastPathComponent < $1.lastPathComponent }
  guard let file = files.first else {
    return nil
  }

  @Dependency(\.storage) var storage
  guard let imageData = try? Data(contentsOf: file) else {
    os_log("[G•] Failed to load screenshot data from file: %{public}s", file.path)
    try? fm.removeItem(at: file)
    storage.removeObject(forKey: file.lastPathComponent)
    return getNextUnprocessedScreenshot(depth: depth + 1)
  }

  guard let metaData = storage.load(
    decoding: ScreenshotMetaData.self,
    forKey: file.lastPathComponent
  )
  else {
    os_log(
      "[G•] Failed to load screenshot data from storage for key: %{public}s",
      file.lastPathComponent
    )
    try? fm.removeItem(at: file)
    storage.removeObject(forKey: file.lastPathComponent)
    return getNextUnprocessedScreenshot(depth: depth + 1)
  }

  return (
    image: UploadScreenshotData(
      data: imageData,
      width: metaData.width,
      height: metaData.height,
      createdAt: metaData.createdAt
    ),
    cleanup: {
      storage.removeObject(forKey: file.lastPathComponent)
      try? fm.removeItem(at: file)
    }
  )
}

struct ScreenshotMetaData: Sendable, Codable {
  let width: Int
  let height: Int
  let createdAt: Date

  var filename: String {
    "screenshot-\(self.createdAt.timeIntervalSinceReferenceDate)-\(UUID()).jpg"
  }
}

extension RecorderClient: TestDependencyKey {
  public static let testValue = RecorderClient()
}

public extension DependencyValues {
  var recorder: RecorderClient {
    get { self[RecorderClient.self] }
    set { self[RecorderClient.self] = newValue }
  }
}

extension URL {
  static var screenshotsDir: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ftc.gertrude-ios.app")?
      .appendingPathComponent("screenshots")
  }
}
