import XCTest
import XExpect

@testable import Api

class EphemeralTests: DependencyTestCase {
  func testAddingAndRetrievingParentToken() async {
    let ephemeral = Ephemeral()
    let parent = Parent.mock
    let token = await ephemeral.createParentIdToken(parent.id)
    let retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.notExpired(parent.id))
    let retrievedAgain = await ephemeral.parentIdFromToken(token)
    expect(retrievedAgain).toEqual(.previouslyRetrieved(parent.id))
  }

  func testExpiredParentTokenReturnsNil() async {
    let ephemeral = Ephemeral()
    let parent = Parent.mock
    let token = await ephemeral.createParentIdToken(
      parent.id,
      expiration: Date.reference - .days(5),
    )
    var retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.expired(parent.id))
    // can retrieve expired multiple times
    retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.expired(parent.id))
  }

  func testUnknownParentTokenReturnsNotFound() async {
    let retrieved = await Ephemeral().parentIdFromToken(UUID())
    expect(retrieved).toEqual(.notFound)
  }
}
