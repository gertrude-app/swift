import Cocoa
import Core
import CoreGraphics
import Dependencies
import Foundation
import SystemConfiguration

#if canImport(ScreenCaptureKit)
  import ScreenCaptureKit
#endif

struct ScreenshotData {
  var data: Data
  var width: Int
  var height: Int
  var displayId: UInt32?
  var createdAt: Date
}

enum ScreenshotError: Error {
  case permissionNotGranted
  case createImageFailed
  case writeToDiskFailed
  case downsampleFailed
  case captureError(Error)
}

@available(macOS 14, *)
@Sendable func takeScreenshot(width: Int) async throws {
  guard currentUserProbablyHasScreen(), screensaverRunning() == false else {
    return
  }

  guard let shareable = try? await SCShareableContent.excludingDesktopWindows(
    false,
    onScreenWindowsOnly: false
  ) else {
    throw ScreenshotError.permissionNotGranted
  }

  let configuration = SCStreamConfiguration()
  var images: [(displayId: UInt32?, image: CGImage)] = []
  images.reserveCapacity(shareable.displays.count)

  @Dependency(\.date.now) var now
  let captureTime = now

  for display in shareable.displays {
    do {
      let image = try await SCScreenshotManager.captureImage(
        contentFilter: SCContentFilter(
          display: display,
          excludingApplications: [],
          exceptingWindows: []
        ),
        configuration: configuration
      )
      guard !image.isBlank else {
        continue
      }
      images.append((display.displayID, image))
    } catch {
      throw ScreenshotError.captureError(error)
    }
  }

  defer { lastImage.replace(with: images) }

  let changedImages = lastImage.withValue { lastBatch in
    images.filter { id, image in
      if let prev = lastBatch.first(where: { $0.displayId == id }),
         prev.image.isNearlyIdenticalTo(image) {
        return false
      } else {
        return true
      }
    }
  }

  for (displayId, image) in changedImages {
    let pngUrl = diskUrl(filename: ".\(now.timeIntervalSince1970)-d\(displayId ?? 0).png")
    defer { try? FileManager.default.removeItem(at: pngUrl) }

    guard writeCGImage(image, to: pngUrl) else {
      throw ScreenshotError.writeToDiskFailed
    }

    guard let jpegData = downsampleToJpeg(imageAt: pngUrl, to: CGFloat(width)) else {
      throw ScreenshotError.downsampleFailed
    }

    await screenshotBuffer.append(ScreenshotData(
      data: jpegData,
      width: width,
      height: Int(Double(image.height) * (Double(width) / Double(image.width))),
      displayId: displayId,
      createdAt: captureTime
    ))
  }
}

@Sendable func takeScreenshotLegacy(width: Int) async throws {
  guard currentUserProbablyHasScreen(), screensaverRunning() == false else {
    return
  }

  guard let fullsize = CGWindowListCreateImage(
    CGRect.infinite,
    .optionAll,
    kCGNullWindowID,
    .nominalResolution
  ) else {
    throw ScreenshotError.createImageFailed
  }

  guard !fullsize.isBlank else {
    return
  }

  defer { lastImage.replace(with: [(nil, fullsize)]) }

  let isNearlyIdentical = lastImage.withValue { displayImages in
    // in the legacy case, we only will ever have a single image with a nil displayId
    guard let lastImage = displayImages.first?.image else {
      return false
    }
    return lastImage.isNearlyIdenticalTo(fullsize)
  }

  guard isNearlyIdentical == false else {
    return
  }

  @Dependency(\.date.now) var now
  let pngUrl = diskUrl(filename: ".\(now.timeIntervalSince1970).png")
  defer { try? FileManager.default.removeItem(at: pngUrl) }

  guard writeCGImage(fullsize, to: pngUrl) else {
    throw ScreenshotError.writeToDiskFailed
  }

  guard let jpegData = downsampleToJpeg(imageAt: pngUrl, to: CGFloat(width)) else {
    throw ScreenshotError.downsampleFailed
  }

  await screenshotBuffer.append(ScreenshotData(
    data: jpegData,
    width: width,
    height: Int(Double(fullsize.height) * (Double(width) / Double(fullsize.width))),
    displayId: nil,
    createdAt: now
  ))
}

// this technique should be reliable for all supported os's, (including catalina)
// and does not cause a system prompt for screen recording permission
// @see https://www.ryanthomson.net/articles/screen-recording-permissions-catalina-mess/
@Sendable func isScreenRecordingPermissionGranted() -> Bool {
  guard let windowList = CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID)
    as NSArray? else { return false }

  for case let windowInfo as NSDictionary in windowList {
    // Ignore windows owned by this application
    let windowPID = windowInfo[kCGWindowOwnerPID] as? pid_t
    if windowPID == NSRunningApplication.current.processIdentifier {
      continue
    }
    // Ignore system UI elements
    if windowInfo[kCGWindowOwnerName] as? String == "Window Server" {
      continue
    }

    if windowInfo[kCGWindowName] != nil {
      return true
    }
  }

  return false
}

// helpers

private func diskUrl(filename: String) -> URL {
  let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  return docsDir.appendingPathComponent(filename)
}

private func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
  guard
    let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil)
  else {
    return false
  }
  CGImageDestinationAddImage(destination, image, nil)
  return CGImageDestinationFinalize(destination)
}

private func downsampleToJpeg(imageAt imageURL: URL, to maxDimension: CGFloat) -> Data? {
  let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
  guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
    return nil
  }

  let options = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceShouldCacheImmediately: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceThumbnailMaxPixelSize: maxDimension,
  ] as CFDictionary

  guard let cgImg = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
    return nil
  }

  let bitmap = NSBitmapImageRep(cgImage: cgImg)
  let props: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.7]
  return bitmap.representation(using: .jpeg, properties: props)
}

func screensaverRunning() -> Bool {
  NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.ScreenSaver.Engine"
}

// @see https://developer.apple.com/forums/thread/707522
func currentUserProbablyHasScreen() -> Bool {
  var uid: uid_t = 0
  SCDynamicStoreCopyConsoleUser(nil, &uid, nil)
  // in my testing, sometimes the console user got stuck at 0 as the
  // `loginwindow` user, so consider the loginwindow the current user as well
  return uid == getuid() || uid == 0
}

private let lastImage = Mutex<[(displayId: UInt32?, image: CGImage)]>([])

internal actor ScreenshotBuffer {
  private var buffer: [ScreenshotData] = []

  func append(_ screenshot: ScreenshotData) {
    if self.buffer.count > 100 {
      self.buffer.removeFirst()
    }
    self.buffer.append(screenshot)
  }

  func removeAll() -> [ScreenshotData] {
    defer { buffer.removeAll() }
    return self.buffer
  }
}

internal let screenshotBuffer = ScreenshotBuffer()
