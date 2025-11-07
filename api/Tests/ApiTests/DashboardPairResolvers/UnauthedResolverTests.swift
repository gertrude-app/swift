import Dependencies
import XCTest
import XExpect

@testable import Api

final class DasboardUnauthedResolverTests: ApiTestCase, @unchecked Sendable {
  let context = Context.mock

  func testLoginFromMagicLink() async throws {
    let parent = try await self.db.create(Parent.random)
    let uuids = MockUUIDs()

    try await withDependencies {
      $0.uuid = .mock(uuids)
      $0.date = .init { Date() }
      $0.ephemeral = .init()
    } operation: {
      let token = await with(dependency: \.ephemeral).createParentIdToken(parent.id)
      let output = try await LoginMagicLink.resolve(with: .init(token: token), in: self.context)
      let parentToken = try await self.db.find(Parent.DashToken.Id(uuids[1]))
      expect(output).toEqual(.init(token: .init(uuids[2]), adminId: parent.id))
      expect(parentToken.value).toEqual(.init(uuids[2]))
      expect(parentToken.parentId).toEqual(parent.id)
    }
  }

  func testRequestMagicLink() async throws {
    let parent = try await self.db.create(Parent.random)

    let (token, output) = try await withUUID {
      try await RequestMagicLink.resolve(
        with: .init(email: parent.email.rawValue, redirect: nil),
        in: .init(requestId: "", dashboardUrl: "/dash", ipAddress: nil),
      )
    }

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].templateModel["url"]!).toContain("/dash/otp/\(token.lowercased)")
    expect(sent.emails[0].templateModel["url"]!).not.toContain("redirect=")
  }

  func testSendMagicLinkWithRedirect() async throws {
    let parent = try await self.db.create(Parent.random)

    let (token, output) = try await withUUID {
      try await RequestMagicLink.resolve(
        with: .init(email: parent.email.rawValue, redirect: "/foo"),
        in: .init(requestId: "", dashboardUrl: "/dash", ipAddress: nil),
      )
    }

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].templateModel["url"]!)
      .toContain("/otp/\(token.lowercased)?redirect=%2Ffoo")
  }

  func testSendMagicLinkToUnknownEmailReturnsSuccessSendingNoAccountEmail() async throws {
    let output = try await RequestMagicLink.resolve(
      with: .init(email: "some@hacker.com", redirect: nil),
      in: self.context,
    )

    expect(output).toEqual(.success)
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].template).toBe("magic-link-no-account")
  }
}
