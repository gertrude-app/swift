import Combine
import CombineSchedulers
import Shared
import XCTest

@testable import AppCore

final class HoneycombLoggerTests: XCTestCase {
  var isConnected = true
  var sendsSuccessfully = true
  var sentEvents: [Honeycomb.Event] = []
  var logger: Honeycomb.AppLogger!
  var scheduler = DispatchQueue.test

  override func setUp() {
    logger = Honeycomb.AppLogger(
      batchSize: 3,
      batchInterval: 5,
      scheduler: scheduler.eraseToAnyScheduler(),
      getIsConnected: { self.isConnected },
      send: { events in
        self.sentEvents.append(contentsOf: events)
        return Just(self.sendsSuccessfully).eraseToAnyPublisher()
      }
    )
  }

  var first: Honeycomb.Event? { logger.events.first }

  func testFailureToSendEventsRequeuesThem() {
    sendsSuccessfully = false // mimic error sending to honeycomb
    logger.info("one")
    logger.info("two")
    logger.info("three")

    XCTAssertEqual(sentEvents.count, 3)
    XCTAssertEqual(logger.events.count, 3)

    sendsSuccessfully = true
    logger.info("four")

    // doesn't immediately keep trying after recent failure
    // waits interval amount
    XCTAssertEqual(sentEvents.count, 3)
    XCTAssertEqual(logger.events.count, 4)

    scheduler.advance(by: 5)
    logger.info("five")

    XCTAssertEqual(sentEvents.count, 8)
    XCTAssertEqual(logger.events.count, 0)
  }

  func testMemoryFailsafe() {
    sendsSuccessfully = false
    // `3` is batch size, so failsafe should drop 3 * 100 events
    for num in 0 ... 302 {
      logger.info("\(num)")
    }
    XCTAssertEqual(logger.events.count, 2)
  }

  func testContinuesToBufferEventsIfNotConnected() {
    isConnected = false // <-- offline!

    logger.info("one")
    logger.info("two")

    XCTAssertEqual(sentEvents.count, 0)

    // normally this would trigger a send, but we're offline
    logger.info("three")
    logger.info("four")
    XCTAssertEqual(sentEvents.count, 0)
    XCTAssertEqual(logger.events.count, 4)

    isConnected = true // <-- back online!
    logger.info("five")
    XCTAssertEqual(sentEvents.count, 5)
    XCTAssertEqual(logger.events.count, 0)

    isConnected = false // <-- back offline!
    for num in 1 ... 10 {
      logger.info("\(num)")
    }
    isConnected = true // <-- back online!

    // scheduled batch job should pick up events accumulated while offline
    scheduler.advance(by: logger.batchInterval)
    XCTAssertEqual(sentEvents.count, 15)
    XCTAssertEqual(logger.events.count, 0)
  }

  func testSendsEventsWhenReachesBatchSize() {
    logger.info("one")
    logger.info("two")

    XCTAssertEqual(sentEvents.count, 0)

    logger.info("three")
    XCTAssertEqual(sentEvents.count, 3)
    XCTAssertEqual(logger.events.count, 0)
  }

  func testSendsAccumulatedEventsEveryBatchInterval() {
    logger.info("one")
    logger.info("two")

    // not enough events to trigger batch send
    XCTAssertEqual(sentEvents.count, 0)

    // but now we pass the batch interval, so send
    scheduler.advance(by: logger.batchInterval)
    XCTAssertEqual(sentEvents.count, 2)
    XCTAssertEqual(logger.events.count, 0)
  }

  func testCreationOfEventsFromLogs() {
    logger.error("some error")
    XCTAssertEqual(first?.data["error"], true)
    XCTAssertEqual(first?.data["log.level"], "error")
    XCTAssertEqual(first?.data["log.message"], "some error")
  }

  func testAttachingArbitraryMetadata() {
    logger.info("some msg", meta: ["foo": "bar", "bool": true])
    XCTAssertEqual(first?.data["foo"], "bar")
    XCTAssertEqual(first?.data["bool"], true)
  }
}
