import Gertie
import XCTest
import XExpect

final class CGImageTests: XCTestCase {
  
  func testIsNearlyIdenticalTo() {
    let imageA = self.pngFixture("identical/1600x670_A.png")
    let imageB = self.pngFixture("identical/1600x670_B.png")
    let imageDiff = self.pngFixture("identical/1600x670_diff.png")
    let largeImageA = self.pngFixture("identical/1920x1080_A.png")
    let largeImageB = self.pngFixture("identical/1920x1080_B.png")
    let hourSmallImageA = self.pngFixture("identical/1600x670_hour_A.png")
    let hourSmallImageB = self.pngFixture("identical/1600x670_hour_B.png")
    
    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageB))
    XCTAssertTrue(imageA.isNearlyIdenticalTo(imageA))
    XCTAssertTrue(largeImageA.isNearlyIdenticalTo(largeImageB))
    XCTAssertTrue(hourSmallImageA.isNearlyIdenticalTo(hourSmallImageB))
    
    XCTAssertFalse(imageA.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageB.isNearlyIdenticalTo(imageDiff))
    XCTAssertFalse(imageA.isNearlyIdenticalTo(largeImageB))
  }
  func testiOSJpgIsNearlyIdenticalTo() {
    XCTAssertTrue(jpegFixture("identical/gerA.JPG")
      .isNearlyIdenticalTo(jpegFixture("identical/gerB.JPG")))
  }
  func testiOSPngIsNearlyIdenticalTo() {
    XCTAssertTrue(pngFixture("identical/ger1.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/ger2.PNG")))
    XCTAssertTrue(pngFixture("identical/ger2.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/ger3.PNG")))
    
    XCTAssertTrue(pngFixture("identical/home1.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/home2.PNG")))
    XCTAssertTrue(pngFixture("identical/home2.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/home3.PNG")))
    
    XCTAssertTrue(pngFixture("identical/apps1.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/apps2.PNG")))
    XCTAssertTrue(pngFixture("identical/apps2.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/apps3.PNG")))
  }
  func testiOSisDifferent() {
    XCTAssertFalse(jpegFixture("iPadA.JPG").isNearlyIdenticalTo(jpegFixture("iPadB.JPG")))
    XCTAssertFalse(pngFixture("identical/apps1.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/ger1.PNG")))
    XCTAssertFalse(pngFixture("identical/home1.PNG")
      .isNearlyIdenticalTo(pngFixture("identical/ger1.PNG")))
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
    CGImage(
      pngDataProviderSource: .init(filename: "./Tests/GertieTests/__fixtures__/\(filename)")!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }
  
  func jpegFixture(_ filename: String) -> CGImage {
    CGImage(
      jpegDataProviderSource: .init(filename: "./Tests/GertieTests/__fixtures__/\(filename)")!,
      decode: nil,
      shouldInterpolate: true,
      intent: .defaultIntent
    )!
  }
}
