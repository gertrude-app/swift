import FilterCore
import Shared
import XCTest

class FilterSuspensionsTests: XCTestCase {
  func testSuspensionCanBeRetrievedBeforeExpiration() {
    let suspensions = FilterSuspensions()
    let suspension = FilterSuspension(scope: .unrestricted, duration: 1000)
    suspensions.set(suspension, userId: 501)
    let retrieved = suspensions.get(userId: 501)
    XCTAssertNotNil(retrieved)
    XCTAssertEqual(retrieved, suspension)
  }

  func testAttemptingToRetrieveExpiredSuspensionReturnsNil() {
    let suspensions = FilterSuspensions()
    let suspension = FilterSuspension(scope: .unrestricted, duration: -1000)
    suspensions.set(suspension, userId: 501)
    let retrieved = suspensions.get(userId: 501)
    XCTAssertNil(retrieved)
  }
}
