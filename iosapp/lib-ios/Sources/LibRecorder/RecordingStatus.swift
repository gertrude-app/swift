//
//  RecordingStatus.swift
//  Gertrude-iOS
//
//  Copyright © 2025 Chris Woolfe. All rights reserved.
//  This software is licensed under the Apache License, Version 2.0
//  with the Commons Clause Restriction on Commercial Sales.
//  See the LICENSE file for details.
//

import Foundation
import os.log

public class RecordingStatus {

  // Any lower than this and it is possible that analyzeForText is
  // called before the previous analyzeForText finishes, thus causing the
  // extension to run out of memory and crash.
  private static let PERIOD_SECONDS: TimeInterval = 5
  private static let WIGGLE: TimeInterval = 1

  private static let isUnitTest = NSClassFromString("XCTest") != nil
  private static let unitTestFile = FileManager.default.temporaryDirectory
    .appendingPathComponent("\(UUID().uuidString).txt")

  public static func didRecordSample() {
    self.writeTime(Date.now)
  }

  public static func recordingStopped() {
    self.writeTime(Date.now.addingTimeInterval(-self.PERIOD_SECONDS - self.WIGGLE))
  }

  public static var isRecording: Bool {
    guard let lastRecordedSampleTime = readTime() else { return false }
    let secondsElasped = Date.now.timeIntervalSince(lastRecordedSampleTime)
    return secondsElasped > 0 && secondsElasped < (self.PERIOD_SECONDS + WIGGLE)
  }

  public static func shouldSample(lastSavedDate: Date?) -> Bool {
    guard let lastSavedDate else {
      return true // Initial condition. Take first screenshot ASAP.
    }
    // Doing abs here guards against attempted bypass via manually changing system time.
    return abs(lastSavedDate.timeIntervalSinceNow) > self.PERIOD_SECONDS
  }

  // MARK: Helper Functions

  static let lastRecordedSampleTimeFile: URL? = {
    #if DEBUG
      if isUnitTest {
        return unitTestFile
      }
    #endif
    let url = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.ftc.gertrude-ios.app"
    )?
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
