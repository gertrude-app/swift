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
  public var unprocessedScreenshot: @Sendable () -> (
    image: UploadScreenshotData,
    cleanup: () -> Void
  )?
  public var events: @Sendable () -> AsyncStream<RecorderEvent> = { AsyncStream { _ in } }
  public var emit: @Sendable (RecorderEvent) -> Void = { _ in }
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

        let data = ScreenshotData(width: img.width, height: img.height, createdAt: img.createdAt)
        let filename = data.filename
        os_log("[G•] storing screenshot to disk for later upload: %{public}s", filename)

        do {
          try img.data.write(to: screenshotsDir.appendingPathComponent(filename))
        } catch {
          return false
        }

        @Dependency(\.storage) var storage
        storage.saveCodable(value: data, forKey: filename)
        return true
      },
      unprocessedScreenshot: { getNextUnprocessedScreenshot() },
      events: {
        AsyncStream<RecorderEvent> { continuation in
          notifier.withValue { notifier in
            notifier.startObserving(name: RecorderEvent.broadcastStarted.rawValue) {
              continuation.yield(.broadcastStarted)
            }
            notifier.startObserving(name: RecorderEvent.broadcastPaused.rawValue) {
              continuation.yield(.broadcastPaused)
            }
            notifier.startObserving(name: RecorderEvent.broadcastResumed.rawValue) {
              continuation.yield(.broadcastResumed)
            }
            notifier.startObserving(name: RecorderEvent.broadcastFinished.rawValue) {
              continuation.yield(.broadcastFinished)
            }
          }
        }
      },
      emit: { event in
        notifier.withValue { $0.postNotification(name: event.rawValue) }
      }
    )
  }
}

public enum RecorderEvent: String, Sendable, Equatable, Codable {
  case broadcastStarted = "com.netrivet.gertrude-ios.app.broadcastStarted"
  case broadcastPaused = "com.netrivet.gertrude-ios.app.broadcastPaused"
  case broadcastResumed = "com.netrivet.gertrude-ios.app.broadcastResumed"
  case broadcastFinished = "com.netrivet.gertrude-ios.app.broadcastFinished"
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

  guard let image = storage.load(decoding: ScreenshotData.self, forKey: file.lastPathComponent)
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
      width: image.width,
      height: image.height,
      createdAt: image.createdAt
    ),
    cleanup: {
      storage.removeObject(forKey: file.lastPathComponent)
      try? fm.removeItem(at: file)
    }
  )
}

struct ScreenshotData: Sendable, Codable {
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
      .containerURL(forSecurityApplicationGroupIdentifier: "group.com.netrivet.gertrude-ios.app")?
      .appendingPathComponent("screenshots")
  }
}

// @see https://ohmyswift.com/blog/2024/08/27/send-data-between-ios-apps-and-extensions-using-darwin-notifications/
private final class DarwinNotificationManager {
  private var callbacks: [String: () -> Void] = [:]

  init() {}

  func postNotification(name: String) {
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterPostNotification(
      notificationCenter,
      CFNotificationName(name as CFString),
      nil,
      nil,
      true
    )
  }

  func startObserving(name: String, callback: @escaping () -> Void) {
    self.callbacks[name] = callback
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterAddObserver(
      notificationCenter,
      Unmanaged.passUnretained(self).toOpaque(),
      DarwinNotificationManager.notificationCallback,
      name as CFString,
      nil,
      .deliverImmediately
    )
  }

  func stopObserving(name: String) {
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterRemoveObserver(
      notificationCenter,
      Unmanaged.passUnretained(self).toOpaque(),
      CFNotificationName(name as CFString),
      nil
    )
    self.callbacks.removeValue(forKey: name)
  }

  private static let notificationCallback: CFNotificationCallback =
    { center, observer, name, _, _ in
      guard let observer else { return }
      let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
      if let name = name?.rawValue as String?,
         let callback = manager.callbacks[name] {
        callback()
      }
    }
}

private let notifier = LockIsolated(DarwinNotificationManager())
