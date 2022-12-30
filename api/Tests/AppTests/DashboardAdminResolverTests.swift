import DuetMock
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

  func testCreatePendingMethod_Text() async throws {
    Current.verificationCode.generate = { 987_654 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .b(.init(phoneNumber: "1234567890")),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: id))

    // verify no db record created
    let preConfirm = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that text was sent
    expect(sent.texts).toEqual([.init(
      to: "1234567890",
      message: "Your verification code is 987654"
    )])
    expect(sent.texts.first?.recipientI164).toEqual("+1234567890")

    // submit the "confirm pending" mutation
    let confirmOuput = try await ConfirmPendingNotificationMethod.resolve(
      with: .init(id: id, code: 987_654),
      in: context(admin)
    )

    expect(confirmOuput).toEqual(.success)

    // verify method now added to db w/ correct info
    let retrieved = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(retrieved?.id.rawValue).toEqual(id)
    expect(retrieved?.adminId).toEqual(admin.id)
    expect(retrieved?.method).toEqual(.text(phoneNumber: "1234567890"))
  }

  func testCreatePendingMethod_Slack() async throws {
    Current.verificationCode.generate = { 123_456 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .c(.init(token: "xoxb-123", channelId: "C123", channelName: "Foo")),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: id))

    // verify no db record created
    let preConfirm = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that slack was sent
    expect(sent.slacks).toHaveCount(1)
    let (slack, token) = try XCTUnwrap(sent.slacks.first)
    expect(token).toBe("xoxb-123")
    expect(slack.channel).toBe("C123")
    expect(slack.text).toContain("123456")

    // submit the "confirm pending" mutation
    let confirmOuput = try await ConfirmPendingNotificationMethod.resolve(
      with: .init(id: id, code: 123_456),
      in: context(admin)
    )

    expect(confirmOuput).toEqual(.success)

    // verify method now added to db w/ correct info
    let retrieved = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(retrieved?.id.rawValue).toEqual(id)
    expect(retrieved?.adminId).toEqual(admin.id)
    expect(retrieved?.method)
      .toEqual(.slack(channelId: "C123", channelName: "Foo", token: "xoxb-123"))
  }

  func testCreatePendingMethod_Email() async throws {
    Current.verificationCode.generate = { 123_456 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .a(.init(email: "blob@blob.com")),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: id))

    // verify no db record created
    let preConfirm = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that email was sent
    expect(sent.emails).toHaveCount(1)
    let email = try XCTUnwrap(sent.emails.first)
    expect(email.firstRecipient).toEqual("blob@blob.com")
    expect(email.text).toContain("123456")

    // submit the "confirm pending" mutation
    let confirmOuput = try await ConfirmPendingNotificationMethod.resolve(
      with: .init(id: id, code: 123_456),
      in: context(admin)
    )

    expect(confirmOuput).toEqual(.success)

    // verify method now added to db w/ correct info
    let retrieved = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(retrieved?.id.rawValue).toEqual(id)
    expect(retrieved?.adminId).toEqual(admin.id)
    expect(retrieved?.method).toEqual(.email(email: "blob@blob.com"))
  }

  func testCreateNewAdminNotification() async throws {
    let admin = try await Entities.admin()
    let method = try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.model.id,
      method: .email(email: "foo@bar.com")
    ))

    let (id, _) = mockUUIDs()
    let output = try await SaveNotification_v0.resolve(
      with: .init(id: nil, methodId: method.id.rawValue, trigger: .unlockRequestSubmitted),
      in: context(admin)
    )

    expect(output).toEqual(.init(id: id))
  }

  func testUpdateAdminNotification() async throws {
    let admin = try await Entities.admin()
    let email = try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.model.id,
      method: .email(email: "foo@bar.com")
    ))
    let text = try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.model.id,
      method: .text(phoneNumber: "1234567890")
    ))
    let notification = try await Current.db.create(AdminNotification(
      adminId: admin.model.id,
      methodId: email.id,
      trigger: .unlockRequestSubmitted
    ))

    let output = try await SaveNotification_v0.resolve(
      with: .init(
        id: notification.id.rawValue,
        methodId: text.id.rawValue, // <-- new method
        trigger: .suspendFilterRequestSubmitted // <-- new trigger
      ),
      in: context(admin)
    )

    expect(output).toEqual(.init(id: notification.id.rawValue))

    let retrieved = try await Current.db.find(notification.id)
    expect(retrieved.methodId).toEqual(text.id)
    expect(retrieved.trigger).toEqual(.suspendFilterRequestSubmitted)
  }

  func testGetIdentifiedApps() async throws {
    try await Current.db.query(IdentifiedApp.self).delete()
    try await Current.db.query(AppCategory.self).delete()
    try await Current.db.query(AppBundleId.self).delete()

    let cat = try await Current.db.create(AppCategory.random)
    let app = IdentifiedApp.random
    app.categoryId = cat.id
    try await Current.db.create(app)
    let bundleId = AppBundleId.random
    bundleId.identifiedAppId = app.id
    try await Current.db.create(bundleId)

    let output = try await GetIdentifiedApps.resolve(in: context(.mock))

    expect(output).toEqual([
      GetIdentifiedApps.App(
        id: app.id.rawValue,
        name: app.name,
        slug: app.slug,
        selectable: app.selectable,
        bundleIds: [.init(from: bundleId)],
        category: .init(from: cat)
      ),
    ])
  }

  // helpers

  private func context(_ admin: Admin) -> AdminContext {
    .init(dashboardUrl: "", admin: admin)
  }

  private func context(_ admin: AdminEntities) -> AdminContext {
    .init(dashboardUrl: "", admin: admin.model)
  }
}
