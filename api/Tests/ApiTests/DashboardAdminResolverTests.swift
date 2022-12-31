import DuetMock
import XCore
import XCTest
import XExpect

@testable import Api

final class DashboardAdminResolverTests: ApiTestCase {

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
      with: .init(userId: user.id),
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
        userId: user.id,
        range: .init(
          start: Date(subtractingDays: 2).isoString,
          end: Date(addingDays: 2).isoString
        )
      ),
      in: context(user.admin)
    )

    // date timezone issues preventing checking whole struct equality
    expect(output.items).toHaveCount(2)
    expect(output.items[0].t2?.id).toEqual(keystrokeLine.id)
    expect(output.items[0].t2?.ids).toEqual([keystrokeLine.id])
    expect(output.items[0].t2?.appName).toEqual(keystrokeLine.appName)
    expect(output.items[0].t2?.line).toEqual(keystrokeLine.line)

    expect(output.items[1].t1?.id).toEqual(screenshot.id)
    expect(output.items[1].t1?.ids).toEqual([screenshot.id])
    expect(output.items[1].t1?.url).toEqual(screenshot.url)
    expect(output.items[1].t1?.width).toEqual(screenshot.width)
    expect(output.items[1].t1?.height).toEqual(screenshot.height)
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
      id: admin.id,
      email: admin.email.rawValue,
      notifications: [.init(
        id: notification.id,
        trigger: notification.trigger,
        methodId: notification.methodId
      )],
      verifiedNotificationMethods: [.t1(.init(id: method.id, email: "blob@blob.com"))]
    ))
  }

  func testCreatePendingMethod_Text() async throws {
    Current.verificationCode.generate = { 987_654 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .t2(.init(phoneNumber: "1234567890")),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: .init(id)))

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
      with: .init(id: .init(id), code: 987_654),
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
      with: .t3(.init(token: "xoxb-123", channelId: "C123", channelName: "Foo")),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: .init(id)))

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
      with: .init(id: .init(id), code: 123_456),
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
      with: .t1(.init(email: "blob@blob.com")),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: .init(id)))

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
      with: .init(id: .init(id), code: 123_456),
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
      with: .init(id: nil, methodId: method.id, trigger: .unlockRequestSubmitted),
      in: context(admin)
    )

    expect(output).toEqual(.init(id: .init(id)))
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
        id: notification.id,
        methodId: text.id, // <-- new method
        trigger: .suspendFilterRequestSubmitted // <-- new trigger
      ),
      in: context(admin)
    )

    expect(output).toEqual(.init(id: notification.id))

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
        id: app.id,
        name: app.name,
        slug: app.slug,
        selectable: app.selectable,
        bundleIds: [.init(from: bundleId)],
        category: .init(from: cat)
      ),
    ])
  }

  func testGetAdminKeychains() async throws {
    let admin = try await Entities.admin().withKeychain()
    let listOutput = try await GetAdminKeychains.resolve(in: context(admin))
    let singleOutput = try await GetAdminKeychain.resolve(
      with: admin.keychain.id,
      in: context(admin)
    )

    let expected = GetAdminKeychains.Keychain(
      id: admin.keychain.id,
      name: admin.keychain.name,
      description: admin.keychain.description,
      isPublic: admin.keychain.isPublic,
      authorId: admin.id,
      keys: [.init(from: admin.key)]
    )

    expect(listOutput).toEqual([expected])
    expect(singleOutput).toEqual(expected)
  }

  func testGetSelectableKeychains() async throws {
    try await Current.db.query(Key.self).delete()
    try await Current.db.query(Keychain.self).delete()

    let admin = try await Entities.admin().withKeychain { keychain, _ in
      keychain.isPublic = false
    }

    let otherAdmin = try await Entities.admin()
    let publicKeychain = Keychain.random
    publicKeychain.authorId = otherAdmin.id
    publicKeychain.isPublic = true
    try await Current.db.create(publicKeychain)

    let output = try await GetSelectableKeychains.resolve(in: context(admin))

    expect(output).toEqual(.init(
      own: [try await .init(from: admin.keychain)],
      public: [try await .init(from: publicKeychain)]
    ))
  }

  func testSaveExistingKeychain() async throws {
    let admin = try await Entities.admin().withKeychain()

    let output = try await SaveKeychain.resolve(
      with: SaveKeychain.Input(
        isNew: false,
        id: admin.keychain.id,
        name: "new name",
        description: "new description",
        isPublic: true
      ),
      in: context(admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(admin.keychain.id)
    expect(retrieved.name).toEqual("new name")
    expect(retrieved.description).toEqual("new description")
    expect(retrieved.isPublic).toEqual(true)
  }

  func testSaveNewKeychain() async throws {
    let admin = try await Entities.admin()
    let id = Keychain.Id()

    let output = try await SaveKeychain.resolve(
      with: SaveKeychain.Input(
        isNew: true,
        id: id,
        name: "some name",
        description: "some description",
        isPublic: false
      ),
      in: context(admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(id)
    expect(retrieved.name).toEqual("some name")
    expect(retrieved.description).toEqual("some description")
    expect(retrieved.isPublic).toEqual(false)
  }

  func testGetSuspendFilterRequest() async throws {
    let user = try await Entities.user().withDevice()
    let request = SuspendFilterRequest.random
    request.deviceId = user.device.id
    try await Current.db.create(request)

    let output = try await GetSuspendFilterRequest.resolve(
      with: request.id,
      in: context(user.admin)
    )

    expect(output.id).toEqual(request.id)
    expect(output.deviceId).toEqual(user.device.id)
    expect(output.userName).toEqual(user.name)
    expect(output.requestedDurationInSeconds).toEqual(request.duration.rawValue)
    expect(output.status).toEqual(request.status)
  }

  func testGetUnlockRequests() async throws {
    let user = try await Entities.user().withDevice()

    let decision = NetworkDecision.random
    decision.deviceId = user.device.id
    decision.appBundleId = "com.rofl.biz"
    try await Current.db.create(decision)

    let request = UnlockRequest.mock
    request.deviceId = user.device.id
    request.status = .pending
    request.requestComment = "please dad"
    request.networkDecisionId = decision.id
    try await Current.db.create(request)

    let output = try await GetUnlockRequest.resolve(
      with: request.id,
      in: context(user.admin)
    )

    expect(output.id).toEqual(request.id)
    expect(output.userId).toEqual(user.id)
    expect(output.userName).toEqual(user.name)
    expect(output.requestComment).toEqual("please dad")
    expect(output.appBundleId).toEqual("com.rofl.biz")

    let list = try await GetUnlockRequests.resolve(in: context(user.admin))
    expect(list).toEqual([output])

    let userList = try await GetUserUnlockRequests.resolve(with: user.id, in: context(user.admin))
    expect(userList).toEqual([output])
  }

  func testUpdateSuspendFilterRequest() async throws {
    let user = try await Entities.user().withDevice()
    let request = SuspendFilterRequest.random
    request.deviceId = user.device.id
    request.status = .pending
    try await Current.db.create(request)

    let output = try await UpdateSuspendFilterRequest.resolve(
      with: UpdateSuspendFilterRequest.Input(
        id: request.id,
        durationInSeconds: 333,
        responseComment: "ok",
        status: .accepted
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(request.id)
    expect(retrieved.duration).toEqual(.init(333))
    expect(retrieved.responseComment).toEqual("ok")
    expect(retrieved.status).toEqual(.accepted)

    // @TODO: test that mac app is notified via websocket
  }

  func testUpdateUnlockRequest() async throws {
    let user = try await Entities.user().withDevice()

    let decision = NetworkDecision.random
    decision.deviceId = user.device.id
    decision.appBundleId = "com.rofl.biz"
    try await Current.db.create(decision)

    let request = UnlockRequest.mock
    request.deviceId = user.device.id
    request.status = .pending
    request.requestComment = "please dad"
    request.networkDecisionId = decision.id
    try await Current.db.create(request)

    let output = try await UpdateUnlockRequest.resolve(
      with: UpdateUnlockRequest.Input(
        id: request.id,
        responseComment: "no way",
        status: .rejected
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(request.id)
    expect(retrieved.responseComment).toEqual("no way")
    expect(retrieved.status).toEqual(.rejected)

    // @TODO: test that mac app is notified via websocket
  }

  func testDeleteActivityItems() async throws {
    let user = try await Entities.user().withDevice()
    let screenshot = Screenshot.random
    screenshot.deviceId = user.device.id
    try await Current.db.create(screenshot)
    let keystrokeLine = KeystrokeLine.random
    keystrokeLine.deviceId = user.device.id
    try await Current.db.create(keystrokeLine)

    let output = try await DeleteActivityItems.resolve(
      with: DeleteActivityItems.Input(
        keystrokeLineIds: [keystrokeLine.id],
        screenshotIds: [screenshot.id]
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)
    expect(try? await Current.db.find(keystrokeLine.id)).toBeNil()
    expect(try? await Current.db.find(screenshot.id)).toBeNil()
  }

  // helpers

  private func context(_ admin: Admin) -> AdminContext {
    .init(dashboardUrl: "", admin: admin)
  }

  private func context(_ admin: AdminEntities) -> AdminContext {
    .init(dashboardUrl: "", admin: admin.model)
  }

  private func context(_ admin: AdminWithKeychainEntities) -> AdminContext {
    .init(dashboardUrl: "", admin: admin.model)
  }
}
