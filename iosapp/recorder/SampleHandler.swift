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
import SensitiveContentAnalysis
import Vision

class SampleHandler: RPBroadcastSampleHandler {
  var lastSavedDate = Date.now
  var previousScreenThumbnail : CGImage?
  let ciContext = CIContext()
  let sensitivityAnalyzer = SCSensitivityAnalyzer()
  
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
    os_log("[G•] saveScreenToPhotos")
    
    guard let currentScreen = getCIImageFrom(sampleBuffer),
          let currentScreenThumbnail = getThumbnailCGImageFrom(currentScreen) else {
      os_log("[G•] Failed to create cgImage.")
      return
    }
    
    if !currentScreenThumbnail.isNearlyIdenticalTo(previousScreenThumbnail) {
      
      guard let currentScreenJpegUrl = saveAsJPEG(currentScreen, name:"currentScreen.jpg")
        else { return }
      
      sensitivityAnalyzer.analyzeImage(at: currentScreenJpegUrl) { analysis, error in
        if let error {
          os_log("[G•] Error analyzing image: \(error.localizedDescription)")
        }
        if let analysis {
          os_log("[G•] isSensitive: \(analysis.isSensitive)")
        }
      }
      
      Task {
        let textAnayzer = VNImageRequestHandler(url: currentScreenJpegUrl)
        let analysis = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        do {
          try textAnayzer.perform([analysis])
        } catch {
          os_log("[G•] Unable to perform the requests: \(error).")
        }
      }

      previousScreenThumbnail = currentScreenThumbnail.copy()
      
      // Assumes permission was granted for the demo. Future work is to send these images to the cloud.
      PHPhotoLibrary.shared().performChanges({
        let options = PHAssetResourceCreationOptions()
        let creationRequest = PHAssetCreationRequest.forAsset()
        creationRequest.addResource(with: .photo, fileURL: currentScreenJpegUrl, options: options)
      }) { success, error in
        if success {
          RecordingStatus.didRecordSample()
        } else {
          os_log("[G•] Error saving image to Photos app: \(String(describing: error))")
        }
      }
    } else {
      os_log("[G•] screen stayed the same")
    }
  }
  
  func recognizeTextHandler(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
      return
    }
    let recognizedStrings = observations.compactMap { observation in
      return observation.topCandidates(1).first?.string
    }
    
    os_log("[G•] Found text: \(recognizedStrings.description, privacy: .public)")
    
  }
  
  private func getCIImageFrom(_ sampleBuffer: CMSampleBuffer) -> CIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      os_log("[G•] CMSampleBufferGetImageBuffer failed.")
      return nil
    }
    return CIImage(cvImageBuffer: imageBuffer)
  }
  
  // Otherwise the extension runs out of memory.
  private func getThumbnailCGImageFrom(_ ciImage: CIImage) -> CGImage? {
    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 0.25, y: 0.25))
    let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent)
    return cgImage
  }
  
  private func saveAsJPEG(_ image: CIImage, name: String) -> URL? {
    guard let destinationURL = try? FileManager.default.url(for:.documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: true)
      .appendingPathComponent(name),
          let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
    else { return nil }
    
    do {
      let options = [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : 1.0]
      try ciContext.writeJPEGRepresentation(of: image,
                                            to: destinationURL,
                                            colorSpace: colorSpace,
                                            options: options)
      ciContext.clearCaches()
      return destinationURL
    } catch {
      return nil
    }
  }
}


