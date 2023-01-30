import CoreGraphics
import XCTest

@testable import AppCore

final class CGImageTests: XCTestCase {

  func testIsNearlyIdenticalTo() {
    let imageA = imageFixture("identical/1600x670_A.png")
    let imageB = imageFixture("identical/1600x670_B.png")
    let imageDiff = imageFixture("identical/1600x670_diff.png")
    let largeImageA = imageFixture("identical/1920x1080_A.png")
    let largeImageB = imageFixture("identical/1920x1080_B.png")
    let hourSmallImageA = imageFixture("identical/1600x670_hour_A.png")
    let hourSmallImageB = imageFixture("identical/1600x670_hour_B.png")

    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageB))
    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageA))
    XCTAssertTrue(largeImageA.isNearlyIdenticalTo(largeImageB))
    XCTAssertTrue(hourSmallImageA.isNearlyIdenticalTo(hourSmallImageB))

    XCTAssertFalse(imageA.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageB.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageA.isNearlyIdenticalTo(largeImageB))
  }

  func testIsBlank() {
    XCTAssertTrue(imageFixture("white.png").isBlank)
    XCTAssertTrue(imageFixture("black.png").isBlank)
    XCTAssertFalse(imageFixture("mixed.png").isBlank)
  }

  func imageFixture(_ filename: String) -> CGImage {
    CGImage(
      pngDataProviderSource: .init(filename: "./Tests/AppCoreTests/__fixtures__/\(filename)")!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }
}
