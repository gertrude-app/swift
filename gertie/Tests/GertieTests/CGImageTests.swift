import Gertie
import XCTest
import XExpect

final class CGImageTests: XCTestCase {
  
  func testIsNearlyIdenticalTo() {
    let imageA = self.pngFixture("1600x670_A.png")
    let imageB = self.pngFixture("1600x670_B.png")
    let imageDiff = self.pngFixture("1600x670_diff.png")
    let largeImageA = self.pngFixture("1920x1080_A.png")
    let largeImageB = self.pngFixture("1920x1080_B.png")
    let hourSmallImageA = self.pngFixture("1600x670_hour_A.png")
    let hourSmallImageB = self.pngFixture("1600x670_hour_B.png")
    
    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageB))
    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageA))
    XCTAssertTrue(largeImageA.isNearlyIdenticalTo(largeImageB))
    XCTAssertTrue(hourSmallImageA.isNearlyIdenticalTo(hourSmallImageB))
    
    XCTAssertFalse(imageA.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageB.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageA.isNearlyIdenticalTo(largeImageB))
  }
  func testiOSJpgIsNearlyIdenticalTo() {
    XCTAssertTrue(jpegFixture("gerA.JPG")
      .isNearlyIdenticalTo(jpegFixture("gerB.JPG")))
  }
  func testiOSPngIsNearlyIdenticalTo() {
    XCTAssertTrue(pngFixture("ger1.PNG")
      .isNearlyIdenticalTo(pngFixture("ger2.PNG")))
    XCTAssertTrue(pngFixture("ger2.PNG")
      .isNearlyIdenticalTo(pngFixture("ger3.PNG")))
    
    XCTAssertTrue(pngFixture("home1.PNG")
      .isNearlyIdenticalTo(pngFixture("home2.PNG")))
    XCTAssertTrue(pngFixture("home2.PNG")
      .isNearlyIdenticalTo(pngFixture("home3.PNG")))
    
    XCTAssertTrue(pngFixture("apps1.PNG")
      .isNearlyIdenticalTo(pngFixture("apps2.PNG")))
    XCTAssertTrue(pngFixture("apps2.PNG")
      .isNearlyIdenticalTo(pngFixture("apps3.PNG")))
  }
  func testiOSisDifferent() {
    XCTAssertFalse(jpegFixture("iPadA.JPG").isNearlyIdenticalTo(jpegFixture("iPadB.JPG")))
    XCTAssertFalse(pngFixture("apps1.PNG")
      .isNearlyIdenticalTo(pngFixture("ger1.PNG")))
    XCTAssertFalse(pngFixture("home1.PNG")
      .isNearlyIdenticalTo(pngFixture("ger1.PNG")))
  }
  
  func testAntialiasingIdentical() {
    let realA = self.jpegFixture("one.jpeg")
    let realB = self.jpegFixture("two.jpeg")
    
    XCTAssertTrue(realA.isNearlyIdenticalTo(realB))
  }
  
  func testIsBlank() {
    XCTAssertTrue(self.pngFixture("white.png").isBlank)
    XCTAssertTrue(self.pngFixture("black.png").isBlank)
    XCTAssertFalse(self.pngFixture("mixed.png").isBlank)
  }
  
  func pngFixture(_ filename: String) -> CGImage {
    let path = Bundle.module.pathForImageResource(filename)!
    return CGImage(
      pngDataProviderSource: .init(filename: path)!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }
  
  func jpegFixture(_ filename: String) -> CGImage {
    let path = Bundle.module.pathForImageResource(filename)!
    return CGImage(
      jpegDataProviderSource: .init(filename: path)!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }
}
