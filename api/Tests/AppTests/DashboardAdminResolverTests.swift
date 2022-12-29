import XCore
import XCTest
import XExpect

@testable import App

final class DashboardAdminResolverTests: AppTestCase {

  func testCreateBillingPortalSessionHappyPath() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionId = .init(rawValue: "sub_123")
      $0.subscriptionStatus = .active
    }

    Current.stripe.getSubscription = { subId in
      expect(subId).toBe("sub_123")
      return .init(id: "sub_123", status: .active, customer: "cus_123")
    }

    Current.stripe.createBillingPortalSession = { cusId in
      expect(cusId).toBe("cus_123")
      return .init(id: "bps_123", url: "bps-url")
    }

    let output = try await CreateBillingPortalSession.resolve(in: context(admin))

    expect(output).toEqual(.init(url: "bps-url"))
  }

  func testCreatePendingAppConnection() async throws {
    Current.verificationCode.generate = { 1234 }
    let user = try await Entities.user()

    let output = try await CreatePendingAppConnection.resolve(
      with: .init(userId: user.id.rawValue),
      in: context(user.admin)
    )

    expect(output).toEqual(.init(code: 1234))
  }

  func testGetActivityDay() async throws {
    Current.date = { Date() }
    let user = try await Entities.user().withDevice()
    let screenshot = Screenshot.random
    screenshot.deviceId = user.device.id
    try await Current.db.create(screenshot)
    let keystrokeLine = KeystrokeLine.random
    keystrokeLine.deviceId = user.device.id
    try await Current.db.create(keystrokeLine)

    let output = try await GetUserActivityDay.resolve(
      with: .init(
        userId: user.id.rawValue,
        range: .init(
          start: Date(subtractingDays: 2).isoString,
          end: Date(addingDays: 2).isoString
        )
      ),
      in: context(user.admin)
    )

    // date timezone issues preventing checking whole struct equality
    expect(output.items).toHaveCount(2)
    expect(output.items[0].b?.id).toEqual(keystrokeLine.id.rawValue)
    expect(output.items[0].b?.ids).toEqual([keystrokeLine.id.rawValue])
    expect(output.items[0].b?.appName).toEqual(keystrokeLine.appName)
    expect(output.items[0].b?.line).toEqual(keystrokeLine.line)

    expect(output.items[1].a?.id).toEqual(screenshot.id.rawValue)
    expect(output.items[1].a?.ids).toEqual([screenshot.id.rawValue])
    expect(output.items[1].a?.url).toEqual(screenshot.url)
    expect(output.items[1].a?.width).toEqual(screenshot.width)
    expect(output.items[1].a?.height).toEqual(screenshot.height)
  }

  func testGetAdminWithNotifications() async throws {
    let admin = try await Entities.admin()
    let method = AdminVerifiedNotificationMethod(
      adminId: admin.id,
      method: .email(email: "blob@blob.com")
    )
    try await Current.db.create(method)
    let notification = AdminNotification.random
    notification.adminId = admin.id
    notification.methodId = method.id
    try await Current.db.create(notification)

    let output = try await GetAdmin.resolve(in: context(admin))

    expect(output).toEqual(.init(
      id: admin.id.rawValue,
      email: admin.email.rawValue,
      notifications: [
        .init(
          id: notification.id.rawValue,
          trigger: notification.trigger,
          methodId: notification.methodId.rawValue
        ),
      ],
      verifiedNotificationMethods: [.a(.init(id: method.id.rawValue, email: "blob@blob.com"))]
    ))
  }

  // helpers

  private func context(_ admin: Admin) -> AdminContext {
    .init(dashboardUrl: "", admin: admin)
  }

  private func context(_ admin: AdminEntities) -> AdminContext {
    .init(dashboardUrl: "", admin: admin.model)
  }
}
