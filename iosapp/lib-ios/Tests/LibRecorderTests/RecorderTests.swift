import XCTest
@testable import LibRecorder

final class RecorderTests: XCTestCase {
  
  // Note: these tests should not work in parallel.
  
  func test01_IsRecording() {
    XCTAssertFalse(RecordingStatus.isRecording)
    RecordingStatus.didRecordSample()
    XCTAssertTrue(RecordingStatus.isRecording)
    RecordingStatus.recordingStopped()
  }
  
  // Assumes PERIOD_SECONDS = 5s and WIGGLE = 1s
  func test02_Timing() {
    XCTAssertFalse(RecordingStatus.isRecording)
    RecordingStatus.didRecordSample()
    XCTAssertTrue(RecordingStatus.isRecording)
    Thread.sleep(forTimeInterval: 1)
    XCTAssertTrue(RecordingStatus.isRecording)
    Thread.sleep(forTimeInterval: 4)
    XCTAssertTrue(RecordingStatus.isRecording)
    Thread.sleep(forTimeInterval: 1)
    XCTAssertFalse(RecordingStatus.isRecording)
  }
 
  func test03_RecordAgain() {
    XCTAssertFalse(RecordingStatus.isRecording)
    RecordingStatus.didRecordSample()
    Thread.sleep(forTimeInterval: 5)
    XCTAssertTrue(RecordingStatus.isRecording)
    RecordingStatus.didRecordSample()
    Thread.sleep(forTimeInterval: 5)
    XCTAssertTrue(RecordingStatus.isRecording)
    Thread.sleep(forTimeInterval: 3)
    XCTAssertFalse(RecordingStatus.isRecording)
  }
  
  func test04_RecordingStopped() {
    XCTAssertFalse(RecordingStatus.isRecording)
    RecordingStatus.didRecordSample()
    Thread.sleep(forTimeInterval: 1)
    RecordingStatus.recordingStopped()
    XCTAssertFalse(RecordingStatus.isRecording)
  }
  func test05_RecordingStoppedMultiple() {
    XCTAssertFalse(RecordingStatus.isRecording)
    RecordingStatus.didRecordSample()
    RecordingStatus.recordingStopped()
    RecordingStatus.recordingStopped()
    RecordingStatus.recordingStopped()
    RecordingStatus.recordingStopped()
    RecordingStatus.recordingStopped()
    XCTAssertFalse(RecordingStatus.isRecording)
    RecordingStatus.recordingStopped()
    RecordingStatus.recordingStopped()
    RecordingStatus.recordingStopped()
    RecordingStatus.didRecordSample()
    Thread.sleep(forTimeInterval: 7)
    XCTAssertFalse(RecordingStatus.isRecording)
  }
  
  // For when the child changes the system clock in an attempt to bypass.
  func testTimingWithWrongSystemClock() {
    let now = Date.now
    let oneSecondAgo = now.addingTimeInterval(-1)
    let oneSecondFuture = now.addingTimeInterval(1)
    let fourSecondsAgo = now.addingTimeInterval(-4)
    let fourSecondsFuture = now.addingTimeInterval(4)
    let tenSecondsAgo = now.addingTimeInterval(-10)
    let tenSecondsFuture = now.addingTimeInterval(10)
    
    XCTAssertFalse(_isRecording(lastRecordedSampleTime: nil, currentTime: now))
            
    XCTAssertTrue(_isRecording(lastRecordedSampleTime: oneSecondAgo, currentTime: now))
    XCTAssertTrue(_isRecording(lastRecordedSampleTime: fourSecondsAgo, currentTime: now))
    XCTAssertFalse(_isRecording(lastRecordedSampleTime: tenSecondsAgo, currentTime: now))

    XCTAssertFalse(_isRecording(lastRecordedSampleTime: oneSecondFuture, currentTime: now))
    XCTAssertFalse(_isRecording(lastRecordedSampleTime: fourSecondsFuture, currentTime: now))
    XCTAssertFalse(_isRecording(lastRecordedSampleTime: tenSecondsFuture, currentTime: now))
    
  }
  
  // Same logic as RecordingStatus
  func _isRecording(lastRecordedSampleTime: Date?, currentTime: Date) -> Bool {
      guard let lastRecordedSampleTime = lastRecordedSampleTime else { return false }
      let secondsElasped = currentTime.timeIntervalSince(lastRecordedSampleTime)
      return secondsElasped > 0 && secondsElasped < (4 + 1)
  }
  
}
