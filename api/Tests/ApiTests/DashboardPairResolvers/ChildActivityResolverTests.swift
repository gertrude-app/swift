import XCTest
import XExpect

@testable import Api

final class ChildActivityResolverTests: ApiTestCase, @unchecked Sendable {
  func testFlagActivityItems() async throws {
    let child = try await self.userWithDevice()
    var screenshot = Screenshot.random
    screenshot.computerUserId = child.device.id
    screenshot.flagged = nil
    var keystrokeLine = KeystrokeLine.random
    keystrokeLine.computerUserId = child.device.id
    keystrokeLine.flagged = nil
    try await self.db.create(screenshot)
    try await self.db.create(keystrokeLine)

    var output = try await FlagActivityItems.resolve(
      with: [keystrokeLine.id.rawValue],
      in: context(child.admin)
    )

    let retrievedScreenshot = try await self.db.find(screenshot.id)
    let retrievedKeystrokeLine = try await self.db.find(keystrokeLine.id)
    expect(retrievedScreenshot.flagged).toBeNil()
    expect(retrievedKeystrokeLine.flagged).not.toBeNil()
    expect(output).toEqual(.success)

    output = try await FlagActivityItems.resolve(
      with: [screenshot.id.rawValue],
      in: context(child.admin)
    )

    let retrievedScreenshot2 = try await self.db.find(screenshot.id)
    let retrievedKeystrokeLine2 = try await self.db.find(keystrokeLine.id)
    expect(retrievedScreenshot2.flagged).not.toBeNil()
    expect(retrievedKeystrokeLine2.flagged).not.toBeNil()
    expect(output).toEqual(.success)

    output = try await FlagActivityItems.resolve(
      with: [screenshot.id.rawValue],
      in: context(child.admin)
    )

    // toggles if already flagged
    let retrievedScreenshot3 = try await self.db.find(screenshot.id)
    expect(retrievedScreenshot3.flagged).toBeNil()
  }

  func testGetActivityDay() async throws {
    let user = try await self.userWithDevice()
    var screenshot = Screenshot.random
    screenshot.computerUserId = user.device.id
    screenshot.createdAt = .reference - 1
    try await self.db.create(screenshot)
    var keystrokeLine = KeystrokeLine.random
    keystrokeLine.computerUserId = user.device.id
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
      flagged: keystrokeLine.flagged != nil,
      createdAt: keystrokeLine.createdAt
    ))

    expect(output.items.last?.screenshot).toEqual(.init(
      id: screenshot.id,
      ids: [screenshot.id],
      url: screenshot.url,
      width: screenshot.width,
      height: screenshot.height,
      duringSuspension: screenshot.filterSuspended,
      flagged: screenshot.flagged != nil,
      createdAt: screenshot.createdAt
    ))
  }

  @MainActor
  func testCombinedUserActivity() async throws {
    let twoDaysAgo = Date.reference - .days(2)

    let child1 = try await self.userWithDevice()
    var screenshot = Screenshot.mock
    screenshot.computerUserId = child1.device.id
    screenshot.createdAt = .reference - 5
    var flaggedOldScreenshot = Screenshot.mock
    flaggedOldScreenshot.computerUserId = child1.device.id
    flaggedOldScreenshot.flagged = .reference - .days(20)
    // too old to be included, but should be returned because flagged
    flaggedOldScreenshot.createdAt = .reference - .days(30)
    try await self.db.create([screenshot, flaggedOldScreenshot])
    var keystrokeLine = KeystrokeLine.mock
    keystrokeLine.computerUserId = child1.device.id
    keystrokeLine.createdAt = .reference - 4
    try await self.db.create(keystrokeLine)

    var child2 = try await self.userWithDevice()
    child2.model.parentId = child1.parentId
    try await self.db.update(child2.model)
    var screenshot2 = Screenshot.mock
    screenshot2.computerUserId = child2.device.id
    screenshot2.createdAt = .reference - 3
    try await self.db.create(screenshot2)
    var keystrokeLine2 = KeystrokeLine.mock
    keystrokeLine2.computerUserId = child2.device.id
    keystrokeLine2.createdAt = .reference - 2
    keystrokeLine2.deletedAt = .reference - 1 // <-- soft-deleted
    try await self.db.create(keystrokeLine2)

    // test getting the activity overview summaries
    let summary = try await CombinedUsersActivitySummaries.resolve(
      in: context(child1.admin)
    )

    expect(summary).toEqual(
      [
        .init(
          date: Calendar.current.startOfDay(for: keystrokeLine2.createdAt),
          numApproved: 1,
          numFlagged: 0,
          numTotal: 4
        ),
        .init(
          date: Calendar.current.startOfDay(for: flaggedOldScreenshot.createdAt),
          numApproved: 0,
          numFlagged: 1,
          numTotal: 1
        ),
      ]
    )

    let dateRange = DateRange(
      start: twoDaysAgo.isoString,
      end: twoDaysAgo.advanced(by: .days(4)).isoString
    )

    // test getting the activity day detail (screenshots and keystrokes)
    let dayOutput = try await CombinedUsersActivityFeed.resolve(
      with: .init(range: dateRange),
      in: context(child1.admin)
    )

    expect(dayOutput).toHaveCount(2)
    let childDay1 = dayOutput[0]
    expect(childDay1).toEqual(CombinedUsersActivityFeed.UserDay(
      userName: child1.name,
      showSuspensionActivity: child1.showSuspensionActivity,
      numDeleted: 0,
      items: [
        .keystrokeLine(.init(
          id: keystrokeLine.id,
          ids: [keystrokeLine.id],
          appName: keystrokeLine.appName,
          line: keystrokeLine.line,
          duringSuspension: keystrokeLine.filterSuspended,
          flagged: false,
          createdAt: keystrokeLine.createdAt
        )),
        .screenshot(.init(
          id: screenshot.id,
          ids: [screenshot.id],
          url: screenshot.url,
          width: screenshot.width,
          height: screenshot.height,
          duringSuspension: screenshot.filterSuspended,
          flagged: false,
          createdAt: screenshot.createdAt
        )),
      ]
    ))

    let childDay2 = dayOutput[1]
    expect(childDay2).toEqual(CombinedUsersActivityFeed.UserDay(
      userName: child2.name,
      showSuspensionActivity: child2.showSuspensionActivity,
      numDeleted: 1,
      items: [.screenshot(.init(
        id: screenshot2.id,
        ids: [screenshot2.id],
        url: screenshot2.url,
        width: screenshot2.width,
        height: screenshot2.height,
        duringSuspension: screenshot2.filterSuspended,
        flagged: false,
        createdAt: screenshot2.createdAt
      ))]
    ))
  }

  func testDeleteActivityItems_v2() async throws {
    let user = try await self.userWithDevice()
    var screenshot = Screenshot.mock
    screenshot.computerUserId = user.device.id
    var flagged = Screenshot.mock
    flagged.computerUserId = user.device.id
    flagged.flagged = Date()
    try await self.db.create([screenshot, flagged])
    var keystrokeLine = KeystrokeLine.mock
    keystrokeLine.computerUserId = user.device.id
    try await self.db.create(keystrokeLine)

    let output = try await DeleteActivityItems_v2.resolve(
      with: DeleteActivityItems_v2.Input(
        keystrokeLineIds: [keystrokeLine.id],
        screenshotIds: [screenshot.id, flagged.id]
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)
    await expect(try? self.db.find(keystrokeLine.id)).toBeNil()
    await expect(try? self.db.find(screenshot.id)).toBeNil()

    // flagged item not deleted
    await expect(try self.db.find(flagged.id).id).toEqual(flagged.id)
  }
}
