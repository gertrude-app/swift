import Cocoa
import Combine
import CoreGraphics
import SharedCore
import SystemConfiguration

struct ScreenshotClient {
  var take: (Int) -> AnyPublisher<URL, Unit>
}

extension ScreenshotClient {
  static let live = Self { size in
    Future { promise in
      Screenshot.shared.take(width: size) { string in
        guard let urlString = string, let url = URL(string: urlString) else {
          promise(.failure)
          return
        }
        promise(.success(url))
      }
    }
    .eraseToAnyPublisher()
  }
}

extension ScreenshotClient {
  static let noop = Self { _ in Empty().eraseToAnyPublisher() }
}

final class Screenshot {
  static let shared = Screenshot()
  private var lastImage: CGImage?

  func take(width: Int, urlCallback: ((String?) -> Void)? = nil) {
    if !currentUserProbablyHasScreen() {
      log(.screenshot(.info("skipping screenshot, user doesn't have screen")))
      urlCallback?(nil)
      return
    }

    guard
      let fullsize = CGWindowListCreateImage(
        CGRect.infinite,
        .optionAll,
        kCGNullWindowID,
        .nominalResolution
      )
    else {
      log(.screenshot(.error("error taking screenshot", nil)))
      urlCallback?(nil)
      return
    }

    if fullsize.isBlank {
      log(.screenshot(.info("skipping blank screenshot")))
      urlCallback?(nil)
      return
    }

    defer { lastImage = fullsize }
    if lastImage?.isNearlyIdenticalTo(fullsize) == true {
      log(.screenshot(.info("skipping nearly identical screenshot")))
      urlCallback?(nil)
      return
    }

    let tmpFilename = ".\(Date().timeIntervalSince1970).png"
    let tmpFullsizePngUrl = diskUrl(filename: tmpFilename)

    guard writeCGImage(fullsize, to: tmpFullsizePngUrl) else {
      log(.screenshot(.error("failed to write screenshot to disk", nil)))
      urlCallback?(nil)
      return
    }

    defer { try? FileManager.default.removeItem(at: tmpFullsizePngUrl) }

    guard let jpegData = downsampleToJpeg(imageAt: tmpFullsizePngUrl, to: CGFloat(width)) else {
      log(.screenshot(.error("failed to get downsampled jpeg data", nil)))
      urlCallback?(nil)
      return
    }

    let height = Int(Double(fullsize.height) * (Double(width) / Double(fullsize.width)))

    Current.api.uploadScreenshot(jpegData, width, height, urlCallback)
  }

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

    let options =
      [
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

  init() {}
}

// helpers

// @see https://developer.apple.com/forums/thread/707522
func currentUserProbablyHasScreen() -> Bool {
  var uid: uid_t = 0
  SCDynamicStoreCopyConsoleUser(nil, &uid, nil)
  // in my testing, sometimes the console user got stuck at 0 as the
  // `loginwindow` user, so consider the loginwindow the current user as well
  return uid == getuid() || uid == 0
}
