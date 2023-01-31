import CoreGraphics
import XCTest

@testable import AppCore

final class CGImageTests: XCTestCase {

  func testIsNearlyIdenticalTo() {
    let imageA = pngFixture("identical/1600x670_A.png")
    let imageB = pngFixture("identical/1600x670_B.png")
    let imageDiff = pngFixture("identical/1600x670_diff.png")
    let largeImageA = pngFixture("identical/1920x1080_A.png")
    let largeImageB = pngFixture("identical/1920x1080_B.png")
    let hourSmallImageA = pngFixture("identical/1600x670_hour_A.png")
    let hourSmallImageB = pngFixture("identical/1600x670_hour_B.png")

    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageB))
    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageA))
    XCTAssertTrue(largeImageA.isNearlyIdenticalTo(largeImageB))
    XCTAssertTrue(hourSmallImageA.isNearlyIdenticalTo(hourSmallImageB))

    XCTAssertFalse(imageA.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageB.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageA.isNearlyIdenticalTo(largeImageB))
  }

  func testAntialiasingIdentical() {
    let realA = jpegFixture("one.jpeg")
    let realB = jpegFixture("two.jpeg")

    // these are nearly identical, except for antialiasing
    // ideally, this should be true, but it's not
    // it might be better to stop just counting different pixels,
    // but rather adding up the difference between rgb values
    // this might allow us to detect antialiasing
    XCTAssertFalse(realA.isNearlyIdenticalTo(realB))
  }

  func testIsBlank() {
    XCTAssertTrue(pngFixture("white.png").isBlank)
    XCTAssertTrue(pngFixture("black.png").isBlank)
    XCTAssertFalse(pngFixture("mixed.png").isBlank)
  }

  func pngFixture(_ filename: String) -> CGImage {
    CGImage(
      pngDataProviderSource: .init(filename: "./Tests/AppCoreTests/__fixtures__/\(filename)")!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }

  func jpegFixture(_ filename: String) -> CGImage {
    CGImage(
      jpegDataProviderSource: .init(filename: "./Tests/AppCoreTests/__fixtures__/\(filename)")!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }
}
