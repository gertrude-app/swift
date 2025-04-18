import Combine
import Dependencies
import LibClients
import os.log
import ReplayKit

// import UIKit

public struct SampleHandlerProxy {
  private var lastSavedDate = Date()
  private let ciContext = CIContext()

  @Dependency(\.date) private var date
  @Dependency(\.recorder) private var recorder

  public init() {}

  public func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
  }

  public func broadcastPaused() {
    // User has requested to pause the broadcast. Samples will stop being delivered.
  }

  public func broadcastResumed() {
    // User has requested to resume the broadcast. Samples delivery will resume.
  }

  public func broadcastFinished() {
    // User has requested to finish the broadcast.
  }

  public mutating func shouldUploadBuffer() -> Bool {
    if abs(self.lastSavedDate.timeIntervalSinceNow) > 5 {
      self.lastSavedDate = Date()
      return true
    } else {
      return false
    }
  }

  private func getCGImage(from sampleBuffer: CMSampleBuffer, maxWidth: CGFloat) -> CGImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      os_log("[G•] CMSampleBufferGetImageBuffer failed.")
      return nil
    }
    let scaled = scale(CIImage(cvImageBuffer: imageBuffer), maxWidth: maxWidth)
    return self.ciContext.createCGImage(scaled, from: scaled.extent)
  }

  public func processVideoBufferForUpload(_ buffer: CMSampleBuffer) {
    guard let cgImage = getCGImage(from: buffer, maxWidth: 800) else {
      os_log("[G•] Failed to create CGImage from CMSampleBuffer")
      return
    }

    #if os(iOS)
      let uiImage = UIImage(cgImage: cgImage)
      guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else {
        os_log("[G•] Failed to create jpeg Data from CGImage")
        return
      }
    #else
      let bitmap = NSBitmapImageRep(cgImage: cgImage)
      let props: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.7]
      guard let jpegData = bitmap.representation(using: .jpeg, properties: props) else {
        os_log("[G•] Failed to create jpeg Data from CGImage")
        return
      }
    #endif

    os_log("[G•] Saving screenshot for upload: %{public}s", "\(cgImage.width)x\(cgImage.height)")

    if !self.recorder.saveScreenshotForUpload(.init(
      data: jpegData,
      width: cgImage.width,
      height: cgImage.height,
      createdAt: self.date.now
    )) {
      // TODO: bail/end suspension if won't save
    }
  }
}

func scale(_ image: CIImage, maxWidth: CGFloat) -> CIImage {
  let width = image.extent.width
  guard width > maxWidth else { return image }
  let scale = maxWidth / width
  return image.transformed(by: .init(scaleX: scale, y: scale))
}
