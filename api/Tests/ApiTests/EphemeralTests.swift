import XCTest
import XExpect

@testable import Api

class EphemeralTests: XCTestCase {
  func testAddingAndRetrievingAdminToken() async {
    let ephemeral = Ephemeral()
    let admin = Admin.mock
    let token = await ephemeral.createAdminIdToken(admin.id)
    let retrieved = await ephemeral.adminIdFromToken(token)
    expect(retrieved).toEqual(.notExpired(admin.id))
    let retrievedAgain = await ephemeral.adminIdFromToken(token)
    expect(retrievedAgain).toEqual(.previouslyRetrieved(admin.id))
  }

  func testExpiredAdminTokenReturnsNil() async {
    Current.date = { Date() }
    let ephemeral = Ephemeral()
    let admin = Admin.mock
    let token = await ephemeral.createAdminIdToken(admin.id, expiration: Date(subtractingDays: 5))
    var retrieved = await ephemeral.adminIdFromToken(token)
    expect(retrieved).toEqual(.expired(admin.id))
    // can retrieve expired multiple times
    retrieved = await ephemeral.adminIdFromToken(token)
    expect(retrieved).toEqual(.expired(admin.id))
  }

  func testUnknownAdminTokenReturnsNotFound() async {
    let retrieved = await Ephemeral().adminIdFromToken(UUID())
    expect(retrieved).toEqual(.notFound)
  }
}
