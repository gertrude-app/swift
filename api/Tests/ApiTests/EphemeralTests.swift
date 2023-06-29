import XCTest
import XExpect

@testable import Api

class EphemeralTests: XCTestCase {
  func testAddingAndRetrievingToken() async {
    let ephemeral = Ephemeral()
    let admin = Admin.mock
    let token = await ephemeral.createAdminIdToken(admin.id)
    let retrieved = await ephemeral.adminIdFromToken(token)
    expect(retrieved).toEqual(admin.id)
    let retrievedAgain = await ephemeral.adminIdFromToken(token)
    expect(retrievedAgain).toBeNil()
  }

  func testExpiredTokenReturnsNil() async {
    Current.date = Date.init
    let ephemeral = Ephemeral()
    let admin = Admin.mock
    let token = await ephemeral.createAdminIdToken(admin.id, expiration: Date(subtractingDays: 5))
    let retrieved = await ephemeral.adminIdFromToken(token)
    expect(retrieved).toBeNil()
  }
}
