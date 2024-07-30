import Gertie
import XCore
import XCTest
import XExpect

@testable import Api

final class AuthedAdminResolverTests: ApiTestCase {
  func testStripeUrlForBillingPortalSession() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionId = .init(rawValue: "sub_123")
      $0.subscriptionStatus = .paid
    }

    Current.stripe.getSubscription = { subId in
      expect(subId).toBe("sub_123")
      return .init(id: "sub_123", status: .active, customer: "cus_123", currentPeriodEnd: 0)
    }

    Current.stripe.createBillingPortalSession = { cusId in
      expect(cusId).toBe("cus_123")
      return .init(id: "bps_123", url: "bps-url")
    }

    Current.stripe.createCheckoutSession = { _ in fatalError("should not be called") }

    let output = try await StripeUrl.resolve(in: context(admin))

    expect(output).toEqual(.init(url: "bps-url"))
  }

  func testStripeUrlForCheckoutSession() async throws {
    let admin = try await Entities.admin {
      $0.subscriptionId = nil
      $0.subscriptionStatus = .trialing
    }

    Current.stripe.createCheckoutSession = { sessionData in
      expect(sessionData.clientReferenceId).toEqual(admin.id.lowercased)
      expect(sessionData.customerEmail).toEqual(admin.email.rawValue)
      return .init(id: "s1", url: "/checkout-url", subscription: "subsid", clientReferenceId: nil)
    }

    Current.stripe.getSubscription = { _ in fatalError("should not be called") }
    Current.stripe.createBillingPortalSession = { _ in fatalError("should not be called") }

    let output = try await StripeUrl.resolve(in: context(admin))

    expect(output).toEqual(.init(url: "/checkout-url"))
  }

  func testHandleCheckoutSuccess() async throws {
    let sessionId = "cs_123"
    let admin = try await Current.db.create(Admin.random { $0.subscriptionStatus = .trialing })
    Current.date = { Date(timeIntervalSince1970: 0) }

    Current.stripe.getCheckoutSession = { id in
      expect(id).toBe(sessionId)
      return .init(
        id: "cs_123",
        url: nil,
        subscription: "sub_123",
        clientReferenceId: admin.id.lowercased
      )
    }

    Current.stripe.getSubscription = { id in
      expect(id).toBe("sub_123")
      return .init(id: id, status: .active, customer: "cus_123", currentPeriodEnd: 0)
    }

    let output = try await HandleCheckoutSuccess.resolve(
      with: .init(stripeCheckoutSessionId: sessionId),
      in: context(admin)
    )

    expect(output).toEqual(.success)
    let retrieved = try await Current.db.find(admin.id)
    expect(retrieved.subscriptionId).toEqual(.init(rawValue: "sub_123"))
    expect(retrieved.subscriptionStatus).toEqual(.paid)
    expect(retrieved.subscriptionStatusExpiration).toEqual(
      Date(timeIntervalSince1970: 0).advanced(by: .days(33))
    )
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

  func testGetAdminWithNotifications() async throws {
    let admin = try await Entities.admin { $0.subscriptionStatus = .paid }
    let method = AdminVerifiedNotificationMethod(
      adminId: admin.id,
      config: .email(email: "blob@blob.com")
    )
    try await Current.db.create(method)
    var notification = AdminNotification.random
    notification.adminId = admin.id
    notification.methodId = method.id
    try await Current.db.create(notification)

    let output = try await GetAdmin.resolve(in: context(admin))

    expect(output).toEqual(.init(
      id: admin.id,
      email: admin.email.rawValue,
      subscriptionStatus: .paid,
      notifications: [.init(
        id: notification.id,
        trigger: notification.trigger,
        methodId: notification.methodId
      )],
      verifiedNotificationMethods: [.init(id: method.id, config: method.config)],
      hasAdminChild: false
    ))
  }

  func testCreatePendingMethod_Text() async throws {
    Current.verificationCode.generate = { 987_654 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .text(phoneNumber: "+12345678901"),
      in: context(admin)
    )

    expect(output).toEqual(.init(methodId: .init(id)))

    // verify no db record created
    let preConfirm = try? await Current.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that text was sent
    expect(sent.texts).toEqual([.init(
      to: "+12345678901",
      message: "Your verification code is 987654"
    )])

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
    expect(retrieved?.config).toEqual(.text(phoneNumber: "+12345678901"))
  }

  func testCreatePendingMethod_Slack() async throws {
    Current.verificationCode.generate = { 123_456 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .slack(channelId: "C123", channelName: "Foo", token: "xoxb-123"),
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
    expect(retrieved?.config)
      .toEqual(.slack(channelId: "C123", channelName: "Foo", token: "xoxb-123"))
  }

  func testCreatePendingMethod_Email() async throws {
    Current.verificationCode.generate = { 123_456 }
    let admin = try await Entities.admin()
    let (id, _) = mockUUIDs()

    let output = try await CreatePendingNotificationMethod.resolve(
      with: .email(email: "blob@blob.com"),
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
    expect(retrieved?.config).toEqual(.email(email: "blob@blob.com"))
  }

  func testCreateNewAdminNotification() async throws {
    let admin = try await Entities.admin()
    let method = try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.model.id,
      config: .email(email: "foo@bar.com")
    ))

    let output = try await SaveNotification.resolve(
      with: .init(id: .init(), isNew: true, methodId: method.id, trigger: .unlockRequestSubmitted),
      in: context(admin)
    )

    expect(output).toEqual(.success)
  }

  func testDeleteKeyNotifiesConnectedApps() async throws {
    let admin = try await Entities.admin().withKeychain()
    let output = try await DeleteEntity.resolve(
      with: .init(id: admin.key.id.rawValue, type: .key),
      in: context(admin)
    )
    expect(output).toEqual(.success)
    expect(sent.appEvents).toEqual([.keychainUpdated(admin.keychain.id)])
  }

  func testDeletingLastUserDeviceDeletesDevice() async throws {
    let user = try await Entities.user().withDevice()
    _ = try await DeleteEntity.resolve(
      with: .init(id: user.device.id.rawValue, type: .userDevice),
      in: context(user.admin)
    )
    let retrieved = try? await Device.find(user.adminDevice.id)
    expect(retrieved).toBeNil()
  }

  func testDeletingUserDeletesOrphanedDevice() async throws {
    let user = try await Entities.user().withDevice()
    _ = try await DeleteEntity.resolve(
      with: .init(id: user.id.rawValue, type: .user),
      in: context(user.admin)
    )
    let retrieved = try? await Device.find(user.adminDevice.id)
    expect(retrieved).toBeNil()
  }

  func testDeletingAdminDeletesAdminAndCreatesDeletedEntity() async throws {
    try await DeletedEntity.deleteAll()
    let admin = try await Entities.admin()

    _ = try await DeleteEntity.resolve(
      with: .init(id: admin.id.rawValue, type: .admin),
      in: context(admin)
    )

    let deleted = try await DeletedEntity.query().all()
    expect(deleted).toHaveCount(1)
    expect(deleted.first?.type).toEqual("Admin")
    expect(deleted.first?.reason).toEqual("self-deleted from use-case initial screen")
    expect(deleted.first!.data).toContain(admin.id.lowercased)
    expect(try? await Admin.find(admin.id)).toBeNil()
  }

  func testAdminCantDeleteOtherAdmin() async throws {
    let admin1 = try await Entities.admin()
    let admin2 = try await Entities.admin()

    try await expectErrorFrom { [weak self] in
      _ = try await DeleteEntity.resolve(
        with: .init(id: admin2.id.rawValue, type: .admin),
        in: self!.context(admin1)
      )
    }.toContain("Unauthorized")
  }

  func testLogDashboardEvent() async throws {
    try await InterestingEvent.deleteAll()
    let admin = try await Entities.admin()

    let output = try await LogEvent.resolve(
      with: .init(eventId: "123", detail: "detail"),
      in: context(admin)
    )

    expect(output).toEqual(.success)
    let retrieved = try await InterestingEvent.query().all()
    expect(retrieved).toHaveCount(1)
    expect(retrieved.first?.eventId).toEqual("123")
    expect(retrieved.first?.kind).toEqual("event")
    expect(retrieved.first?.detail).toEqual("detail")
  }

  func testUpdateAdminNotification() async throws {
    let admin = try await Entities.admin()
    let email = try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.model.id,
      config: .email(email: "foo@bar.com")
    ))
    let text = try await Current.db.create(AdminVerifiedNotificationMethod(
      adminId: admin.model.id,
      config: .text(phoneNumber: "1234567890")
    ))
    let notification = try await Current.db.create(AdminNotification(
      adminId: admin.model.id,
      methodId: email.id,
      trigger: .unlockRequestSubmitted
    ))

    let output = try await SaveNotification.resolve(
      with: .init(
        id: notification.id,
        isNew: false,
        methodId: text.id, // <-- new method
        trigger: .suspendFilterRequestSubmitted // <-- new trigger
      ),
      in: context(admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(notification.id)
    expect(retrieved.methodId).toEqual(text.id)
    expect(retrieved.trigger).toEqual(.suspendFilterRequestSubmitted)
  }

  func testGetIdentifiedApps() async throws {
    try await Current.db.query(IdentifiedApp.self).delete()
    try await Current.db.query(AppCategory.self).delete()
    try await Current.db.query(AppBundleId.self).delete()

    let cat = try await Current.db.create(AppCategory.random)
    var app = IdentifiedApp.random
    app.categoryId = cat.id
    try await Current.db.create(app)
    var bundleId = AppBundleId.random
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

    let expected = GetAdminKeychains.AdminKeychain(
      summary: KeychainSummary(
        id: admin.keychain.id,
        authorId: admin.id,
        name: admin.keychain.name,
        description: admin.keychain.description,
        isPublic: admin.keychain.isPublic,
        numKeys: 1
      ),
      keys: [.init(from: admin.key, keychainId: admin.keychain.id)]
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
    var publicKeychain = Keychain.random
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
    let admin = try await Entities.admin().withKeychain { keychain, _ in
      keychain.isPublic = false
    }

    let output = try await SaveKeychain.resolve(
      with: SaveKeychain.Input(
        isNew: false,
        id: admin.keychain.id,
        name: "new name",
        description: "new description"
      ),
      in: context(admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(admin.keychain.id)
    expect(retrieved.name).toEqual("new name")
    expect(retrieved.description).toEqual("new description")
    expect(retrieved.isPublic).toEqual(false)
  }

  func testSaveNewKeychain() async throws {
    let admin = try await Entities.admin()
    let id = Keychain.Id()

    let output = try await SaveKeychain.resolve(
      with: SaveKeychain.Input(
        isNew: true,
        id: id,
        name: "some name",
        description: "some description"
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
    var request = SuspendFilterRequest.random
    request.userDeviceId = user.device.id
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

    var request = UnlockRequest.mock
    request.userDeviceId = user.device.id
    request.status = .pending
    request.requestComment = "please dad"
    request.appBundleId = "com.rofl.biz"
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

  func testDecideSuspendFilterRequest_Accepted() async throws {
    let user = try await Entities.user().withDevice { $0.appVersion = "2.1.2" } // <-- new event
    let request = try await Current.db.create(SuspendFilterRequest.random {
      $0.userDeviceId = user.device.id
      $0.status = .pending
    })

    let decision: DecideFilterSuspensionRequest.Decision = .accepted(
      durationInSeconds: 333,
      extraMonitoring: "@55+k"
    )

    let output = try await DecideFilterSuspensionRequest.resolve(
      with: .init(id: request.id, decision: decision, responseComment: "ok"),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(request.id)
    expect(retrieved.duration).toEqual(.init(333))
    expect(retrieved.responseComment).toEqual("ok")
    expect(retrieved.status).toEqual(.accepted)

    expect(sent.appEvents).toEqual([
      .suspendFilterRequestDecided( // <-- new event
        user.device.id,
        .accepted(
          duration: 333,
          extraMonitoring: .addKeyloggingAndSetScreenshotFreq(55)
        ),
        "ok"
      ),
    ])
  }

  func testDecideSuspendFilterRequest_Rejected() async throws {
    let user = try await Entities.user().withDevice { $0.appVersion = "2.0.2" } // <-- old event
    let request = try await Current.db.create(SuspendFilterRequest.random {
      $0.duration = .init(100)
      $0.userDeviceId = user.device.id
      $0.status = .pending
    })

    let output = try await DecideFilterSuspensionRequest.resolve(
      with: .init(id: request.id, decision: .rejected, responseComment: nil),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(request.id)
    expect(retrieved.responseComment).toBeNil()
    expect(retrieved.status).toEqual(.rejected)

    expect(sent.appEvents).toEqual([
      .suspendFilterRequestUpdated(.init( // <-- old event
        userDeviceId: user.device.id,
        status: .rejected,
        duration: 100,
        requestComment: request.requestComment,
        responseComment: nil
      )),
    ])
  }

  func testUpdateUnlockRequest() async throws {
    let user = try await Entities.user().withDevice()

    var request = UnlockRequest.mock
    request.userDeviceId = user.device.id
    request.status = .pending
    request.requestComment = "please dad"
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

    expect(sent.appEvents).toEqual([
      .unlockRequestUpdated(.init(
        userDeviceId: user.device.id,
        status: .rejected,
        target: request.target ?? "",
        comment: "please dad",
        responseComment: "no way"
      )),
    ])
  }

  func testLatestAppVersions() async throws {
    try await Release.deleteAll()
    try await Release.create([
      .mock {
        $0.semver = "2.0.0"
        $0.channel = .stable
      },
      .mock {
        $0.semver = "2.2.0"
        $0.channel = .stable
      },
      .mock {
        $0.semver = "2.5.2"
        $0.channel = .beta
      },
      .mock {
        $0.semver = "2.5.0"
        $0.channel = .beta
      },
      .mock {
        $0.semver = "3.0.0"
        $0.channel = .canary
      },
    ])

    let output = try await LatestAppVersions.resolve(in: context(try await Entities.admin()))

    expect(output).toEqual(.init(stable: "2.2.0", beta: "2.5.2", canary: "3.0.0"))
  }
}
