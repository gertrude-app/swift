//
//  SampleHandler.swift
//  recorder
//
//  Created by home on 2/19/25.
//

import ReplayKit
import Photos
import os.log
import Gertie

class SampleHandler: RPBroadcastSampleHandler {
  var lastSavedDate = Date.now
  var previousScreenThumbnail : CGImage?
  let ciContext = CIContext()
  
  override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
    RecordingStatus.didRecordSample()
  }
  
  override func broadcastPaused() {
    RecordingStatus.recordingStopped()
  }
  
  override func broadcastResumed() {
    RecordingStatus.didRecordSample()
  }
  
  override func broadcastFinished() {
    RecordingStatus.recordingStopped()
  }
  
  override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
    if sampleBufferType == .video && isTime() {
      lastSavedDate = Date.now
      saveScreenToPhotos(sampleBuffer)
    }
  }
  
  private func isTime() -> Bool{
    abs(lastSavedDate.timeIntervalSinceNow) > RecordingStatus.PERIOD_SECONDS
  }
  
  private func saveScreenToPhotos(_ sampleBuffer: CMSampleBuffer) {
    guard let currentScreen = getCIImageFrom(sampleBuffer),
          let currentScreenThumbnail = getThumbnailCGImageFrom(currentScreen) else {
      os_log("[G•] Failed to create cgImage.")
      return
    }
    if !currentScreenThumbnail.isNearlyIdenticalTo(previousScreenThumbnail) {
      previousScreenThumbnail = currentScreenThumbnail.copy()
      NSLog("[G•] screen changed!")
      
      // Assumes permission was granted for the demo. Future work is to send these images to the cloud.
      PHPhotoLibrary.shared().performChanges({
        let options = PHAssetResourceCreationOptions()
        let creationRequest = PHAssetCreationRequest.forAsset()
        if let jpegScreen = UIImage(ciImage: currentScreen).jpegData(compressionQuality: 1.0) {
          creationRequest.addResource(with: .photo, data: jpegScreen, options: options)
        }
      }) { success, error in
        if success {
          RecordingStatus.didRecordSample()
        } else {
          os_log("[G•] Error saving image to Photos app: \(String(describing: error))")
        }
      }
    } else {
      NSLog("[G•] screen stayed the same")
    }
  }
  
  private func getCIImageFrom(_ sampleBuffer: CMSampleBuffer) -> CIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      os_log("[G•] CMSampleBufferGetImageBuffer failed.")
      return nil
    }
    return CIImage(cvImageBuffer: imageBuffer)
  }
  
  // Otherwise the extension runs out of memory.
  func getThumbnailCGImageFrom(_ ciImage: CIImage) -> CGImage? {
    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 0.25, y: 0.25))
    let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent)
    ciContext.clearCaches()
    return cgImage
  }
  
}

