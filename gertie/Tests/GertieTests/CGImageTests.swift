import Gertie
import XCTest
import XExpect

final class CGImageTests: XCTestCase {
  
  func testIsNearlyIdenticalTo() {
    XCTAssertTrue(imageFixture("1600x670_A.png").isNearlyIdenticalTo(imageFixture("1600x670_B.png")))
    XCTAssertTrue(imageFixture("1600x670_A.png").isNearlyIdenticalTo(imageFixture("1600x670_A.png")))
    XCTAssertTrue(imageFixture("1920x1080_A.png").isNearlyIdenticalTo(imageFixture("1920x1080_B.png")))
    XCTAssertTrue(imageFixture("1600x670_hour_A.png").isNearlyIdenticalTo(imageFixture("1600x670_hour_B.png")))
    
    XCTAssertFalse(imageFixture("1600x670_A.png").isNearlyIdenticalTo(imageFixture("1600x670_diff.png")))
    XCTAssertFalse(imageFixture("1600x670_B.png").isNearlyIdenticalTo(imageFixture("1600x670_diff.png")))
    XCTAssertFalse(imageFixture("1600x670_A.png").isNearlyIdenticalTo(imageFixture("1920x1080_B.png")))
  }
  
  func testiOSJpgIsNearlyIdenticalTo() {
    XCTAssertTrue(imageFixture("gerA.JPG").isNearlyIdenticalTo(imageFixture("gerB.JPG")))
  }
  
  func testiOSPngIsNearlyIdenticalTo() {
    XCTAssertTrue(imageFixture("ger1.PNG").isNearlyIdenticalTo(imageFixture("ger2.PNG")))
    XCTAssertTrue(imageFixture("ger2.PNG").isNearlyIdenticalTo(imageFixture("ger3.PNG")))
    
    XCTAssertTrue(imageFixture("home1.PNG").isNearlyIdenticalTo(imageFixture("home2.PNG")))
    XCTAssertTrue(imageFixture("home2.PNG").isNearlyIdenticalTo(imageFixture("home3.PNG")))
    
    XCTAssertTrue(imageFixture("apps1.PNG").isNearlyIdenticalTo(imageFixture("apps2.PNG")))
    XCTAssertTrue(imageFixture("apps2.PNG").isNearlyIdenticalTo(imageFixture("apps3.PNG")))
  }
  
  func testiOSisDifferent() {
    XCTAssertFalse(imageFixture("iPadA.JPG").isNearlyIdenticalTo(imageFixture("iPadB.JPG")))
    XCTAssertFalse(imageFixture("apps1.PNG").isNearlyIdenticalTo(imageFixture("ger1.PNG")))
    XCTAssertFalse(imageFixture("home1.PNG").isNearlyIdenticalTo(imageFixture("ger1.PNG")))
  }
  
  func testAntialiasingIdentical() {
    XCTAssertTrue(imageFixture("one.jpeg").isNearlyIdenticalTo(imageFixture("two.jpeg")))
  }
  
  func testIsBlank() {
    XCTAssertTrue(imageFixture("white.png").isBlank)
    XCTAssertTrue(imageFixture("black.png").isBlank)
    XCTAssertFalse(imageFixture("mixed.png").isBlank)
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

