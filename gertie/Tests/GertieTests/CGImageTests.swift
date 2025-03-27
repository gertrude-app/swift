import Gertie
import XCTest
import XExpect

final class CGImageTests: XCTestCase {

  func testIsNearlyIdenticalTo() {
    XCTAssertTrue(
      self.imageFixture("1600x670_A.png")
        .isNearlyIdenticalTo(self.imageFixture("1600x670_B.png"))
    )
    XCTAssertTrue(
      self.imageFixture("1600x670_A.png")
        .isNearlyIdenticalTo(self.imageFixture("1600x670_A.png"))
    )
    XCTAssertTrue(
      self.imageFixture("1920x1080_A.png")
        .isNearlyIdenticalTo(self.imageFixture("1920x1080_B.png"))
    )
    XCTAssertTrue(
      self.imageFixture("1600x670_hour_A.png")
        .isNearlyIdenticalTo(self.imageFixture("1600x670_hour_B.png"))
    )

    XCTAssertFalse(
      self.imageFixture("1600x670_A.png")
        .isNearlyIdenticalTo(self.imageFixture("1600x670_diff.png"))
    )
    XCTAssertFalse(
      self.imageFixture("1600x670_B.png")
        .isNearlyIdenticalTo(self.imageFixture("1600x670_diff.png"))
    )
    XCTAssertFalse(
      self.imageFixture("1600x670_A.png")
        .isNearlyIdenticalTo(self.imageFixture("1920x1080_B.png"))
    )
  }

  func testiOSJpgIsNearlyIdenticalTo() {
    XCTAssertTrue(self.imageFixture("gerA.JPG").isNearlyIdenticalTo(self.imageFixture("gerB.JPG")))
  }

  func testiOSPngIsNearlyIdenticalTo() {
    XCTAssertTrue(self.imageFixture("ger1.PNG").isNearlyIdenticalTo(self.imageFixture("ger2.PNG")))
    XCTAssertTrue(self.imageFixture("ger2.PNG").isNearlyIdenticalTo(self.imageFixture("ger3.PNG")))

    XCTAssertTrue(
      self.imageFixture("home1.PNG")
        .isNearlyIdenticalTo(self.imageFixture("home2.PNG"))
    )
    XCTAssertTrue(
      self.imageFixture("home2.PNG")
        .isNearlyIdenticalTo(self.imageFixture("home3.PNG"))
    )

    XCTAssertTrue(
      self.imageFixture("apps1.PNG")
        .isNearlyIdenticalTo(self.imageFixture("apps2.PNG"))
    )
    XCTAssertTrue(
      self.imageFixture("apps2.PNG")
        .isNearlyIdenticalTo(self.imageFixture("apps3.PNG"))
    )
  }

  func testiOSisDifferent() {
    XCTAssertFalse(
      self.imageFixture("iPadA.JPG")
        .isNearlyIdenticalTo(self.imageFixture("iPadB.JPG"))
    )
    XCTAssertFalse(
      self.imageFixture("apps1.PNG")
        .isNearlyIdenticalTo(self.imageFixture("ger1.PNG"))
    )
    XCTAssertFalse(
      self.imageFixture("home1.PNG")
        .isNearlyIdenticalTo(self.imageFixture("ger1.PNG"))
    )
  }

  func testAntialiasingIdentical() {
    XCTAssertTrue(self.imageFixture("one.jpeg").isNearlyIdenticalTo(self.imageFixture("two.jpeg")))
  }

  func testIsBlank() {
    XCTAssertTrue(self.imageFixture("white.png").isBlank)
    XCTAssertTrue(self.imageFixture("black.png").isBlank)
    XCTAssertFalse(self.imageFixture("mixed.png").isBlank)
  }

  private func imageFixture(_ filename: String) -> CGImage {
    let path = Bundle.module.pathForImageResource(filename)!
    let url = URL(fileURLWithPath: path)

    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      fatalError("Failed to load image: \(filename)")
    }

    return image
  }
}
