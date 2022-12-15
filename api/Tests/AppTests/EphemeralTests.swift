import XCTest

@testable import App

class EphemeralTests: XCTestCase {
  func testAddingAndRetrievingToken() async {
    let ephemeral = Ephemeral()
    let admin = Admin.mock
    let token = await ephemeral.createMagicLinkToken(admin.id)
    let retrieved = await ephemeral.adminIdFromMagicLinkToken(token)
    expect(retrieved).toEqual(admin.id)
    let retrievedAgain = await ephemeral.adminIdFromMagicLinkToken(token)
    expect(retrievedAgain).toBeNil()
  }

  func testExpiredTokenReturnsNil() async {
    Current.date = Date.init
    let ephemeral = Ephemeral()
    let admin = Admin.mock
    let token = await ephemeral.createMagicLinkToken(admin.id, expiration: Date(subtractingDays: 5))
    let retrieved = await ephemeral.adminIdFromMagicLinkToken(token)
    expect(retrieved).toBeNil()
  }
}
