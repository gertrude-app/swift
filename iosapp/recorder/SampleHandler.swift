//
//  SampleHandler.swift
//  recorder
//
//  Copyright © 2025 Chris Woolfe. All rights reserved.
//  This software is licensed under the Apache License, Version 2.0
//  with the Commons Clause Restriction on Commercial Sales.
//  See the LICENSE file for details.
//

import Darwin
import Gertie
import os.log
import Photos
import ReplayKit
import SensitiveContentAnalysis
import Vision

class SampleHandler: RPBroadcastSampleHandler {
  var lastSavedDate: Date?
  var previousScreenThumbnail: CGImage?
  let ciContext = CIContext()
  let sensitivityAnalyzer = SCSensitivityAnalyzer()
  let halfSize = CGAffineTransform(scaleX: 0.5, y: 0.5)

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
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

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer,
    with sampleBufferType: RPSampleBufferType
  ) {
    guard sampleBufferType == .video, self.isTime else { return }

    self.lastSavedDate = Date.now
    self.processBuffer(sampleBuffer)
  }

  private var isTime: Bool {
    guard let lastSavedDate = self.lastSavedDate else {
      return true // Initial condition. Take first screenshot ASAP.
    }
    // Doing abs here guards against attempted bypass via manually changing system time.
    return abs(lastSavedDate.timeIntervalSinceNow) > RecordingStatus.PERIOD_SECONDS
  }

  private func processBuffer(_ sampleBuffer: CMSampleBuffer) {
    os_log("[G•] processBuffer")

    guard let currentScreen = getCIImageFrom(sampleBuffer),
          let currentScreenThumbnail = getThumbnailCGImageFrom(currentScreen) else {
      os_log("[G•] Failed to create cgImage.")
      return
    }

    if !currentScreenThumbnail.isNearlyIdenticalTo(self.previousScreenThumbnail) {
      self.previousScreenThumbnail = currentScreenThumbnail

      guard let currentScreenJpegUrl = saveAsJPEG(currentScreen, name: "currentScreen.jpg")
      else { return }

      self.analyzeForSensitivity(currentScreenJpegUrl) { isSensitive in
        os_log("[G•] isSensitive: \(isSensitive)")
        self.analyzeForText(currentScreenJpegUrl) { textContent in
          os_log("[G•] Found text: \(textContent.description, privacy: .public)")
          self.logMemoryFootprint()
          self.saveToPhotos(currentScreenJpegUrl)
        }
      }
    } else {
      os_log("[G•] screen stayed the same")
    }
  }

  private func analyzeForSensitivity(_ imageUrl: URL, completion: @escaping (Bool) -> Void) {
    self.sensitivityAnalyzer.analyzeImage(at: imageUrl) { analysis, error in
      var isSensitive = false
      if let error {
        os_log("[G•] Error analyzing image: \(error.localizedDescription)")
      }
      if let analysis {
        isSensitive = analysis.isSensitive
      }
      completion(isSensitive)
    }
  }

  private func analyzeForText(_ imageUrl: URL, completion: @escaping ([String]) -> Void) {
    let analysis = VNRecognizeTextRequest { request, error in
      guard let observations = request.results as? [VNRecognizedTextObservation] else {
        return
      }
      let recognizedStrings = observations.compactMap { observation in
        observation.topCandidates(1).first?.string
      }
      completion(recognizedStrings)
    }
    do {
      try VNImageRequestHandler(url: imageUrl).perform([analysis])
    } catch {
      os_log("[G•] text analysis failed: \(error).")
    }
  }

  private func saveToPhotos(_ imageUrl: URL, completion: @escaping (Bool) -> Void = { _ in }) {
    // Assumes permission was granted for the demo. Future work is to send these images to the cloud.
    PHPhotoLibrary.shared().performChanges({
      let options = PHAssetResourceCreationOptions()
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(with: .photo, fileURL: imageUrl, options: options)
    }) { success, error in
      if success {
        RecordingStatus.didRecordSample()
      } else {
        os_log("[G•] Error saving image to Photos app: \(String(describing: error))")
      }
      completion(success)
    }
  }

  private func getCIImageFrom(_ sampleBuffer: CMSampleBuffer) -> CIImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      os_log("[G•] CMSampleBufferGetImageBuffer failed.")
      return nil
    }
    return CIImage(cvImageBuffer: imageBuffer).transformed(by: self.halfSize)
  }

  // Otherwise the extension runs out of memory.
  private func getThumbnailCGImageFrom(_ ciImage: CIImage) -> CGImage? {
    let scaledImage = ciImage.transformed(by: self.halfSize)
    let cgImage = self.ciContext.createCGImage(scaledImage, from: scaledImage.extent)
    return cgImage
  }

  private func saveAsJPEG(_ image: CIImage, name: String) -> URL? {
    guard let destinationURL = try? FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    .appendingPathComponent(name),
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
    else { return nil }

    do {
      let options = [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.5]
      try self.ciContext.writeJPEGRepresentation(
        of: image,
        to: destinationURL,
        colorSpace: colorSpace,
        options: options
      )
      self.ciContext.clearCaches()
      return destinationURL
    } catch {
      return nil
    }
  }

  // For troubleshooting memory pressure.
  private func logMemoryFootprint() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) /
      mach_msg_type_number_t(MemoryLayout<integer_t>.size)
    let kerr = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    guard kerr == KERN_SUCCESS else {
      print("Error getting task_info: \(kerr)")
      return
    }
    os_log("[G•] Recorder is using: \(info.resident_size / 1024 / 1024) MB")
  }
}
