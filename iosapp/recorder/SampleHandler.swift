//
//  SampleHandler.swift
//  recorder
//
//  Created by home on 2/19/25.
//

import ReplayKit
import Photos
import os.log

class SampleHandler: RPBroadcastSampleHandler {
  
  var lastSavedDate = Date()
  
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
    switch sampleBufferType {
    case .video:
      if abs(lastSavedDate.timeIntervalSinceNow) > RecordingStatus.PERIOD_SECONDS {
        saveSampleBufferToPhotos(sampleBuffer)
        RecordingStatus.didRecordSample()
      }
      break
    default:
      return
    }
  }
  
  private func saveSampleBufferToPhotos(_ sampleBuffer: CMSampleBuffer) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      os_log("[G•] CMSampleBufferGetImageBuffer failed.")
      return
    }
    
    let uiImage = UIImage(ciImage: CIImage(cvImageBuffer: imageBuffer))
    
    guard let imageData = uiImage.jpegData(compressionQuality: 1.0) else {
      os_log("[G•] uiImage.jpegData failed.")
      return
    }
    
    // Assumes permission was granted for the demo. Future work is to send these images to the cloud.
    PHPhotoLibrary.shared().performChanges({
      let options = PHAssetResourceCreationOptions()
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(with: .photo, data: imageData, options: options)
    }) { success, error in
      if success {
        self.lastSavedDate = Date()
      } else {
        os_log("[G•] Error saving image to Photos app: \(String(describing: error))")
      }
    }
    
  }
}

