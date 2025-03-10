import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class LogFilterEventsResolverTests: ApiTestCase, @unchecked Sendable {
  func testLogFilterEvents() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: UnidentifiedApp.self)
    try await self.db.create(UnidentifiedApp(bundleId: "com.widget", count: 3))
    let user = try await self.userWithDevice()
    let xcode = try await self.db
      .create(IdentifiedApp(name: "Xcode", slug: "", launchable: true))
    try await self.db.create(AppBundleId(identifiedAppId: xcode.id, bundleId: "com.xcode"))

    let eventId1 = UUID().lowercased
    let eventId2 = UUID().lowercased

    let input = FilterLogs(
      bundleIds: [
        "com.widget": 3,
        "com.gadget": 2,
        "com.xcode": 1, // <-- identified, ignored
      ],
      events: [
        .init(id: eventId1, detail: "ev 1"): 1,
        .init(id: eventId2, detail: "ev 2"): 4,
      ]
    )

    _ = try await LogFilterEvents.resolve(with: input, in: user.context)

    let event1 = try await InterestingEvent.query()
      .where(.eventId == eventId1)
      .first(in: self.db)

    let event2 = try await InterestingEvent.query()
      .where(.eventId == eventId2)
      .first(in: self.db)

    expect(event1.detail).toEqual("ev 1")
    expect(event2.detail).toEqual("ev 2 (4x)") // <-- appends non-1 count
    expect(event1.computerUserId).toEqual(user.device.id)
    expect(event2.computerUserId).toEqual(user.device.id)
    expect(event1.kind).toEqual("event")
    expect(event2.kind).toEqual("event")
    expect(event1.context).toEqual("macapp-filter")

    let unidentifiedApps = try await UnidentifiedApp.query()
      .orderBy(.bundleId, .asc)
      .all(in: self.db)

    expect(unidentifiedApps.count).toEqual(2) // <-- identified ignored
    expect(unidentifiedApps[0].bundleId).toEqual("com.gadget")
    expect(unidentifiedApps[0].count).toEqual(2)
    expect(unidentifiedApps[1].bundleId).toEqual("com.widget")
    expect(unidentifiedApps[1].count).toEqual(6) // <-- added to existing count

    // ensure no crash if all bundle ids already identified
    let input2 = FilterLogs(bundleIds: ["com.xcode": 1], events: [:])
    let output = try await LogFilterEvents.resolve(with: input2, in: user.context)
    expect(output).toEqual(.success)
  }
}
