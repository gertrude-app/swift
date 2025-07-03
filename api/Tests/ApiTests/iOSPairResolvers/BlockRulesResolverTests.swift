import GertieIOS
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class BlockRulesResolverTests: ApiTestCase, @unchecked Sendable {
  func testBlockRules() async throws {
    let vendorId = UUID()
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    try await self.db.delete(all: IOSApp.BlockRule.self)
    try await self.db.create([
      IOSApp.BlockRule(rule: .urlContains("bad"), groupId: .init(gifs)),
      IOSApp.BlockRule(rule: .urlContains("cat"), groupId: .init(ads)), // <-- skip, disabled group
      IOSApp.BlockRule(vendorId: .init(vendorId), rule: .urlContains("x1")), // <-- include
      IOSApp.BlockRule(vendorId: .init(), rule: .urlContains("x2")),
      IOSApp.BlockRule(rule: .urlContains("nope"), groupId: nil),
    ])

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [.ads], vendorId: vendorId, version: "1.0"),
      in: .mock
    )
    expect(Set(rules)).toEqual([.urlContains("bad"), .urlContains("x1")])
  }

  func testBlockRuleIgnoresZeroAskNotToTrackVendorId() async throws {
    // not sure if users can do this with gertrude, but when you "ask not to track" on iOS
    // my understanding is that it just means the vendorId is set to zero, so we don't want
    // to ever consider these vendor ids for customizations
    let zeroVid = UUID("00000000-0000-0000-0000-000000000000")!
    let gifs = CreateBlockGroups.GroupIds().gifs
    try await self.db.delete(all: IOSApp.BlockRule.self)
    try await self.db.create([
      IOSApp.BlockRule(rule: .urlContains("bad"), groupId: .init(gifs)),
      IOSApp.BlockRule(vendorId: .init(zeroVid), rule: .urlContains("x1")), // <-- skip
    ])

    let rules = try await BlockRules_v2.resolve(
      with: .init(disabledGroups: [.ads], vendorId: zeroVid, version: "1.0"),
      in: .mock
    )
    expect(rules).toEqual([.urlContains("bad")])
  }

  func testDefaultBlockRulesRetrievesAllWithGroup() async throws {
    let gifs = CreateBlockGroups.GroupIds().gifs
    let ads = CreateBlockGroups.GroupIds().ads
    try await self.db.delete(all: IOSApp.BlockRule.self)
    try await self.db.create([
      IOSApp.BlockRule(rule: .urlContains("bad"), groupId: .init(gifs)),
      IOSApp.BlockRule(rule: .urlContains("thing"), groupId: nil), // <-- skip, no group
      IOSApp.BlockRule(rule: .urlContains("cat"), groupId: .init(ads)),
    ])

    let defaultRules = try await DefaultBlockRules.resolve(
      with: .init(vendorId: nil, version: "1.0"),
      in: .mock
    )
    expect(defaultRules).toEqual([.urlContains("bad"), .urlContains("cat")])
  }

  // MARK: v1 legacy tests below

  func testBlockRules_v1() async throws {
    let rules = try await BlockRules.resolve(with: .init(vendorId: UUID()), in: .mock)
    expect(rules).toEqual(BlockRule.defaults)
  }

  func testCustomizedBlockRules_v1() async throws {
    let vendorId = UUID(uuidString: "2cada392-9d09-4425-bec2-b0c4e3aeafec")!
    let rules = try await BlockRules.resolve(with: .init(vendorId: vendorId), in: .mock)
    expect(rules.contains(
      .both(
        .bundleIdContains(".com.apple.MobileSMS"),
        .targetContains("amp-api-edge.apps.apple.com")
      )
    )).toEqual(true)
  }
}
