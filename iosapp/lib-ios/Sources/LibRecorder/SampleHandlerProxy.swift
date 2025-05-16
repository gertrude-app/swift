import Combine
import Dependencies
import LibClients
import os.log
import ReplayKit

public protocol FinishableBroadcast {
  func finishWithError(_ error: any Error)
}

let failedToSave: Error = NSError(
  domain: "com.ftc.gertrude-ios.app.finishWithError",
  code: 1111,
  userInfo: [NSLocalizedDescriptionKey: "Failed to save screenshot to device."]
)

public struct SampleHandlerProxy {
  private var lastSavedDate: Date?
  private let ciContext = CIContext()
  private let finisher: FinishableBroadcast
  private var previousScreenThumbnail: CGImage?
  private var uploadTask: Task<Void, Never>?
  let halfSize = CGAffineTransform(scaleX: 0.5, y: 0.5)

  @Dependency(\.date) private var date
  @Dependency(\.recorder) private var recorder

  public init(finisher: FinishableBroadcast) {
    self.finisher = finisher
  }

  public mutating func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    self.uploadTask = self.recorder.startUploadTask()
  }

  public func broadcastPaused() {
    self.uploadTask?.cancel()
  }

  public mutating func broadcastResumed() {
    self.uploadTask = self.recorder.startUploadTask()
  }

  public func broadcastFinished() {
    self.uploadTask?.cancel()
  }

  public mutating func shouldUploadBuffer() -> Bool {
    guard let lastSavedDate = self.lastSavedDate else {
      self.lastSavedDate = self.date.now
      return true // Initial condition. Take first screenshot ASAP.
    }
    if abs(lastSavedDate.timeIntervalSinceNow) > 5 {
      self.lastSavedDate = self.date.now
      return true
    } else {
      return false
    }
  }

  public mutating func processVideoBufferForUpload(_ buffer: CMSampleBuffer) {

    guard let currentScreen = getCIImageFrom(buffer),
          let currentScreenThumbnail = getThumbnailCGImageFrom(currentScreen) else {
      os_log("[G•] Failed to create cgImage.")
      return
    }
    let width = Int(currentScreen.extent.width)
    let height = Int(currentScreen.extent.height)

    if !currentScreenThumbnail.isNearlyIdenticalTo(self.previousScreenThumbnail) {
      self.previousScreenThumbnail = currentScreenThumbnail

      guard let currentScreenJpeg = jpegData(from: currentScreen) else { return }
      self.ciContext.clearCaches()

      os_log(
        "[G•] CCW screenshot at: %{public}s",
        "\(self.date.now.timeIntervalSinceReferenceDate)"
      )

      if !self.recorder.saveScreenshotForUpload(.init(
        data: currentScreenJpeg,
        width: width,
        height: height,
        createdAt: self.date.now
      )) {
        self.finisher.finishWithError(failedToSave)
      }
      os_log("[G•] Saving screenshot for upload: %{public}s", "\(width)x\(height)")
    } else {
      os_log("[G•] Ignoring unchanged screen")
      self.ciContext.clearCaches()
    }
  }

  private func getCIImageFrom(_ sampleBuffer: CMSampleBuffer) -> CIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      os_log("[G•] CMSampleBufferGetImageBuffer failed.")
      return nil
    }
    return CIImage(cvImageBuffer: imageBuffer)
      .transformed(by: self.halfSize)
      .oriented(self.upright(self.getOrientationOf(sampleBuffer)))
  }

  private func upright(_ orientation: CGImagePropertyOrientation?) -> CGImagePropertyOrientation {
    switch orientation {
    case .left:
      .right
    case .right:
      .left
    case .rightMirrored:
      .leftMirrored
    case .leftMirrored:
      .rightMirrored
    default:
      orientation ?? .up
    }
  }

  func getOrientationOf(_ buffer: CMSampleBuffer) -> CGImagePropertyOrientation? {
    (CMGetAttachment(
      buffer,
      key: RPVideoSampleOrientationKey as CFString,
      attachmentModeOut: nil
    ) as? NSNumber)
      .flatMap { CGImagePropertyOrientation(rawValue: $0.uint32Value) }
  }

  // Otherwise the extension runs out of memory.
  private func getThumbnailCGImageFrom(_ ciImage: CIImage) -> CGImage? {
    let scaledImage = ciImage.transformed(by: self.halfSize)
    let cgImage = self.ciContext.createCGImage(scaledImage, from: scaledImage.extent)
    return cgImage
  }

  private func jpegData(from ciImage: CIImage) -> Data? {
    guard let colorSpace = ciImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
      os_log("[G•] Error: suitable color space for jpeg screenshot not found.")
      return nil
    }
    return self.ciContext.jpegRepresentation(
      of: ciImage,
      colorSpace: colorSpace,
      options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7]
    )
  }
}
