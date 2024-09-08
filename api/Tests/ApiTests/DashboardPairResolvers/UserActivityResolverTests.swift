import XCTest
import XExpect

@testable import Api

final class UserActivityResolverTests: ApiTestCase {
  func testGetActivityDay() async throws {
    let user = try await Entities.user().withDevice()
    var screenshot = Screenshot.random
    screenshot.userDeviceId = user.device.id
    screenshot.createdAt = .reference - 1
    try await self.db.create(screenshot)
    var keystrokeLine = KeystrokeLine.random
    keystrokeLine.userDeviceId = user.device.id
    keystrokeLine.createdAt = .reference
    try await self.db.create(keystrokeLine)
    let twoDaysAgo = Date.reference - .days(2)

    let output = try await UserActivityFeed.resolve(
      with: .init(
        userId: user.id,
        range: .init(
          start: twoDaysAgo.isoString,
          end: Date.reference.isoString
        )
      ),
      in: context(user.admin)
    )

    expect(output.userName).toEqual(user.name)
    expect(output.numDeleted).toEqual(0)
    expect(output.items).toHaveCount(2)

    expect(output.items.first?.keystrokeLine).toEqual(.init(
      id: keystrokeLine.id,
      ids: [keystrokeLine.id],
      appName: keystrokeLine.appName,
      line: keystrokeLine.line,
      duringSuspension: keystrokeLine.filterSuspended,
      createdAt: keystrokeLine.createdAt
    ))

    expect(output.items.last?.screenshot).toEqual(.init(
      id: screenshot.id,
      ids: [screenshot.id],
      url: screenshot.url,
      width: screenshot.width,
      height: screenshot.height,
      duringSuspension: screenshot.filterSuspended,
      createdAt: screenshot.createdAt
    ))
  }

  @MainActor
  func testCombinedUserActivity() async throws {
    let twoDaysAgo = Date.reference - .days(2)

    let user1 = try await Entities.user().withDevice()
    var screenshot = Screenshot.random
    screenshot.userDeviceId = user1.device.id
    screenshot.createdAt = .reference - 5
    try await self.db.create(screenshot)
    var keystrokeLine = KeystrokeLine.random
    keystrokeLine.userDeviceId = user1.device.id
    keystrokeLine.createdAt = .reference - 4
    try await self.db.create(keystrokeLine)

    var user2 = try await Entities.user().withDevice()
    user2.model.adminId = user1.adminId
    try await self.db.update(user2.model)
    var screenshot2 = Screenshot.random
    screenshot2.userDeviceId = user2.device.id
    screenshot2.createdAt = .reference - 3
    try await self.db.create(screenshot2)
    var keystrokeLine2 = KeystrokeLine.random
    keystrokeLine2.userDeviceId = user2.device.id
    keystrokeLine2.createdAt = .reference - 2
    keystrokeLine2.deletedAt = .reference - 1 // <-- soft-deleted
    try await self.db.create(keystrokeLine2)

    let dateRange = DateRange(
      start: twoDaysAgo.isoString,
      end: twoDaysAgo.advanced(by: .days(4)).isoString
    )

    // test getting the activity overview summaries
    let summaryOutput = try await CombinedUsersActivitySummaries.resolve(
      with: [dateRange],
      in: context(user1.admin)
    )

    expect(summaryOutput).toHaveCount(1)
    let day = summaryOutput[0]
    expect(day.numApproved).toEqual(1)
    expect(day.totalItems).toEqual(4)

    // test getting the activity day detail (screenshots and keystrokes)
    let dayOutput = try await CombinedUsersActivityFeed.resolve(
      with: .init(range: dateRange),
      in: context(user1.admin)
    )

    expect(dayOutput).toHaveCount(2)
    let userDay1 = dayOutput[0]
    expect(userDay1.userName).toEqual(user1.name)
    expect(userDay1.numDeleted).toEqual(0)
    expect(userDay1.items).toHaveCount(2)

    expect(userDay1.items.first?.keystrokeLine).toEqual(.init(
      id: keystrokeLine.id,
      ids: [keystrokeLine.id],
      appName: keystrokeLine.appName,
      line: keystrokeLine.line,
      duringSuspension: keystrokeLine.filterSuspended,
      createdAt: keystrokeLine.createdAt
    ))

    expect(userDay1.items.last?.screenshot).toEqual(.init(
      id: screenshot.id,
      ids: [screenshot.id],
      url: screenshot.url,
      width: screenshot.width,
      height: screenshot.height,
      duringSuspension: screenshot.filterSuspended,
      createdAt: screenshot.createdAt
    ))

    let userDay2 = dayOutput[1]
    expect(userDay2.userName).toEqual(user2.name)
    expect(userDay2.numDeleted).toEqual(1)
    expect(userDay2.items).toHaveCount(1)

    expect(userDay2.items.first?.screenshot).toEqual(.init(
      id: screenshot2.id,
      ids: [screenshot2.id],
      url: screenshot2.url,
      width: screenshot2.width,
      height: screenshot2.height,
      duringSuspension: screenshot2.filterSuspended,
      createdAt: screenshot2.createdAt
    ))
  }

  func testDeleteActivityItems_v2() async throws {
    let user = try await Entities.user().withDevice()
    var screenshot = Screenshot.random
    screenshot.userDeviceId = user.device.id
    try await self.db.create(screenshot)
    var keystrokeLine = KeystrokeLine.random
    keystrokeLine.userDeviceId = user.device.id
    try await self.db.create(keystrokeLine)

    let output = try await DeleteActivityItems_v2.resolve(
      with: DeleteActivityItems_v2.Input(
        keystrokeLineIds: [keystrokeLine.id],
        screenshotIds: [screenshot.id]
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)
    expect(try? await self.db.find(keystrokeLine.id)).toBeNil()
    expect(try? await self.db.find(screenshot.id)).toBeNil()
  }
}
