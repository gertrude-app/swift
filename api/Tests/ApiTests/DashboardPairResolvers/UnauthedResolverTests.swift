import Dependencies
import XCTest
import XExpect

@testable import Api

final class DasboardUnauthedResolverTests: ApiTestCase {
  let context = Context.mock

  func testLoginFromMagicLink() async throws {
    let admin = try await self.db.create(Admin.random)
    let uuids = MockUUIDs()

    try await withDependencies {
      $0.uuid = .mock(uuids)
      $0.date = .init { Date() }
      $0.ephemeral = .init()
    } operation: {
      let token = await with(dependency: \.ephemeral).createAdminIdToken(admin.id)
      let output = try await LoginMagicLink.resolve(with: .init(token: token), in: self.context)
      let adminToken = try await self.db.find(AdminToken.Id(uuids[1]))
      expect(output).toEqual(.init(token: .init(uuids[2]), adminId: admin.id))
      expect(adminToken.value).toEqual(.init(uuids[2]))
      expect(adminToken.adminId).toEqual(admin.id)
    }
  }

  func testRequestMagicLink() async throws {
    let admin = try await self.db.create(Admin.random)

    let (token, output) = try await withUUID {
      try await RequestMagicLink.resolve(
        with: .init(email: admin.email.rawValue, redirect: nil),
        in: .init(requestId: "", dashboardUrl: "/dash", ipAddress: nil)
      )
    }

    expect(output).toEqual(.success)
    expect(sent.sendgridEmails).toHaveCount(1)
    expect(sent.sendgridEmails.first!.text).toContain("href='/dash/otp/\(token.lowercased)'")
    expect(sent.sendgridEmails.first!.text).not.toContain("redirect=")
  }

  func testSendMagicLinkWithRedirect() async throws {
    let admin = try await self.db.create(Admin.random)

    let (token, output) = try await withUUID {
      try await RequestMagicLink.resolve(
        with: .init(email: admin.email.rawValue, redirect: "/foo"),
        in: .init(requestId: "", dashboardUrl: "/dash", ipAddress: nil)
      )
    }

    expect(output).toEqual(.success)
    expect(sent.sendgridEmails).toHaveCount(1)
    expect(sent.sendgridEmails.first!.text).toContain("/otp/\(token.lowercased)?redirect=%2Ffoo")
  }

  func testSendMagicLinkToUnknownEmailReturnsSuccessSendingNoAccountEmail() async throws {
    let output = try await RequestMagicLink.resolve(
      with: .init(email: "some@hacker.com", redirect: nil),
      in: self.context
    )

    expect(output).toEqual(.success)
    expect(sent.sendgridEmails).toHaveCount(1)
    expect(sent.sendgridEmails.first!.text).toContain("no Gertrude account exists")
  }
}
