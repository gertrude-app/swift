import GertieIOS
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class BlockRulesResolverTests: ApiTestCase {
  func testBlockRules() async throws {
    let rules = try await BlockRules.resolve(
      with: .init(vendorId: UUID()),
      in: .mock
    )

    expect(rules).toEqual(BlockRule.defaults)
  }

  func testHarrietsBlockRules() async throws {
    let vendorId = UUID(uuidString: "2cada392-9d09-4425-bec2-b0c4e3aeafec")!
    let rules = try await BlockRules.resolve(
      with: .init(vendorId: vendorId),
      in: .mock
    )

    let expected = BlockRule.defaults + [
      .both(
        .bundleIdContains(".com.apple.MobileSMS"),
        .targetContains("amp-api-edge.apps.apple.com")
      ),
    ]

    expect(rules).toEqual(expected)
  }
}
