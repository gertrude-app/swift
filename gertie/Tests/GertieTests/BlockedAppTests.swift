import Gertie
import XCTest
import XExpect

final class BlockedAppTests: XCTestCase {
  func testBlockedAppBlocksIfNameExactMatch() {
    let blocked = BlockedApp(identifier: "PhotoBooth")
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "PhotoBooth"), at: Date()))
      .toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "PhotoBooth"), at: Date()))
      .toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "PhotoBooth2"), at: Date()))
      .toBeFalse()
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "PhotoBooth2"), at: Date()))
      .toBeFalse()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "FaceSkype"), at: Date()))
      .toBeFalse()
  }

  func testBlockedAppBlocksIfIdentifierEqualsBundleId() {
    let blocked = BlockedApp(identifier: "weird")
    expect(blocked.blocks(app: .init(bundleId: "weird"), at: Date())).toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "com.weird"), at: Date())).toBeFalse()
  }

  func testIdentifierWithDotTestedAsBundleIdFragment() {
    let blocked = BlockedApp(identifier: "com.app")
    expect(blocked.blocks(app: .init(bundleId: "com.not-match"), at: Date())).toBeFalse()
    // exact match blocked
    expect(blocked.blocks(app: .init(bundleId: "com.app"), at: Date())).toBeTrue()
    // block if identifier looks like a bundle id (i.e., has a dot)
    // and is CONTAINED in the real bundle id
    expect(blocked.blocks(app: .init(bundleId: "1234ABC.com.app"), at: Date())).toBeTrue()
  }
}
