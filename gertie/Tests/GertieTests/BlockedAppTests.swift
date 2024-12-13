import Gertie
import XCTest
import XExpect

final class BlockedAppTests: XCTestCase {
  func testBlockedAppBlocksIfNameExactMatch() {
    let blocked = BlockedApp(identifier: "PhotoBooth")
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "PhotoBooth"))).toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "PhotoBooth"))).toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "PhotoBooth2"))).toBeFalse()
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "PhotoBooth2"))).toBeFalse()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "FaceSkype"))).toBeFalse()
  }

  func testBlockedAppBlocksIfIdentifierEqualsBundleId() {
    let blocked = BlockedApp(identifier: "weird")
    expect(blocked.blocks(app: .init(bundleId: "weird"))).toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "com.weird"))).toBeFalse()
  }

  func testIdentifierWithDotTestedAsBundleIdFragment() {
    let blocked = BlockedApp(identifier: "com.app")
    expect(blocked.blocks(app: .init(bundleId: "com.not-match"))).toBeFalse()
    // exact match blocked
    expect(blocked.blocks(app: .init(bundleId: "com.app"))).toBeTrue()
    // block if identifier looks like a bundle id (i.e., has a dot)
    // and is CONTAINED in the real bundle id
    expect(blocked.blocks(app: .init(bundleId: "1234ABC.com.app"))).toBeTrue()
  }
}
