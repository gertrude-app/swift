import Cocoa
import Core
import CoreGraphics
import Dependencies
import Foundation
import SystemConfiguration

typealias ScreenshotData = (data: Data, width: Int, height: Int, createdAt: Date)

@Sendable func takeScreenshot(width: Int) async throws {
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

  defer {
    lastImage.replace(with: fullsize)
  }

  let isNearlyIdentical = lastImage.withValue { lastImage in
    lastImage?.isNearlyIdenticalTo(fullsize) == true
  }

  guard !isNearlyIdentical else {
    return
  }

  let tmpFilename = ".\(Date().timeIntervalSince1970).png"
  let tmpFullsizePngUrl = diskUrl(filename: tmpFilename)

  guard writeCGImage(fullsize, to: tmpFullsizePngUrl) else {
    throw ScreenshotError.writeToDiskFailed
  }

  defer {
    try? FileManager.default.removeItem(at: tmpFullsizePngUrl)
  }

  guard let jpegData = downsampleToJpeg(imageAt: tmpFullsizePngUrl, to: CGFloat(width)) else {
    throw ScreenshotError.downsampleFailed
  }

  let height = Int(Double(fullsize.height) * (Double(width) / Double(fullsize.width)))

  @Dependency(\.date.now) var now
  let screenshot = (data: jpegData, width: width, height: height, createdAt: now)
  await screenshotBuffer.append(screenshot)
}

enum ScreenshotError: Error {
  case createImageFailed
  case writeToDiskFailed
  case downsampleFailed
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

private let lastImage = Mutex<CGImage?>(nil)

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
