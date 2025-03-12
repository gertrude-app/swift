//  RecordingStatus.swift
//  Gertrude-iOS
//
//  Created by home on 2/19/25.

import Foundation
import os.log

class RecordingStatus {
  static let PERIOD_SECONDS: TimeInterval = 4
  
  static func didRecordSample() {
    writeTime(Date.now)
  }
  static func recordingStopped() {
    writeTime(Date.now.addingTimeInterval(-PERIOD_SECONDS))
  }
  static func isRecording() -> Bool {
    guard let lastRecordedSampleTime = readTime() else { return false }
    let secondsElasped = Date.now.timeIntervalSince(lastRecordedSampleTime)
    return secondsElasped > 0 && secondsElasped < (PERIOD_SECONDS + 2)
  }
  
  // MARK: Helper Functions
  
  private static let lastRecordedSampleTimeFile: URL? = {
    let url = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.ftc.gertrude-ios.app")?
      .appendingPathComponent("lastRecordedSampleTime.txt")
    if url == nil {
      os_log("[G•] File not found: lastRecordedSampleTimeFile is nil")
    }
    return url
  }()
  
  private static func writeTime(_ date: Date) {
    guard let url = lastRecordedSampleTimeFile else { return }
    let stringDate = String(date.timeIntervalSince1970)
    do {
      try stringDate.write(to: url, atomically: true, encoding: .utf8)
    } catch {
      os_log("[G•] Error writing lastRecordedSampleTimeFile")
    }
  }
  
  private static func readTime() -> Date? {
    guard let url = lastRecordedSampleTimeFile,
          let timeString = try? String(contentsOf: url, encoding: .utf8),
          let timeInterval = TimeInterval(timeString) else {
      os_log("[G•] Error parsing lastRecordedSampleTimeFile")
      return nil
    }
    return Date(timeIntervalSince1970: timeInterval)
  }
}
