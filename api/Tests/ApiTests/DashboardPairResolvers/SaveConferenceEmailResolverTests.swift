import XCore
import XCTest
import XExpect

@testable import Api

final class SaveConferenceEmailResolverTests: ApiTestCase {
  func testSaveConferenceEmailResolver() async throws {
    try await self.db.delete(all: InterestingEvent.self)
    let input = SaveConferenceEmail.Input(email: "a@b.com", source: .booth)

    let output = try await SaveConferenceEmail.resolve(with: input, in: .mock)

    expect(output).toEqual(.success)
    let events = try await self.db.select(all: InterestingEvent.self)
    let expected = "SaveConferenceEmail: a@b.com, source: booth"
    expect(events).toHaveCount(1)
    expect(events[0].detail).toEqual(expected)
    expect(sent.slacks).toHaveCount(1)
    expect(sent.slacks[0].message.content).toEqual(.text(expected))
  }
}
