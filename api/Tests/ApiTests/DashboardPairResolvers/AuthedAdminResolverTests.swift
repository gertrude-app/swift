import Dependencies
import Gertie
import XCore
import XCTest
import XExpect

@testable import Api

final class AuthedAdminResolverTests: ApiTestCase, @unchecked Sendable {
  func testStripeUrlForBillingPortalSession() async throws {
    let admin = try await self.admin {
      $0.subscriptionId = .init(rawValue: "sub_123")
      $0.subscriptionStatus = .paid
    }

    let output = try await withDependencies {
      $0.stripe.getSubscription = { subId in
        expect(subId).toBe("sub_123")
        return .init(id: "sub_123", status: .active, customer: "cus_123", currentPeriodEnd: 0)
      }
      $0.stripe.createBillingPortalSession = { cusId in
        expect(cusId).toBe("cus_123")
        return .init(id: "bps_123", url: "bps-url")
      }
    } operation: {
      try await StripeUrl.resolve(in: context(admin))
    }

    expect(output).toEqual(.init(url: "bps-url"))
  }

  func testStripeUrlForCheckoutSession() async throws {
    let admin = try await self.admin {
      $0.subscriptionId = nil
      $0.subscriptionStatus = .trialing
    }

    let output = try await withDependencies {
      $0.stripe.createCheckoutSession = { sessionData in
        expect(sessionData.clientReferenceId).toEqual(admin.id.lowercased)
        expect(sessionData.customerEmail).toEqual(admin.email.rawValue)
        return .init(id: "s1", url: "/checkout-url", subscription: "subsid", clientReferenceId: nil)
      }
    } operation: {
      try await StripeUrl.resolve(in: context(admin))
    }

    expect(output).toEqual(.init(url: "/checkout-url"))
  }

  func testHandleCheckoutSuccess() async throws {
    let sessionId = "cs_123"
    let admin = try await self.db.create(Admin.random { $0.subscriptionStatus = .trialing })

    let output = try await withDependencies {
      $0.stripe.getCheckoutSession = { id in
        expect(id).toBe(sessionId)
        return .init(
          id: "cs_123",
          url: nil,
          subscription: "sub_123",
          clientReferenceId: admin.id.lowercased
        )
      }
      $0.stripe.getSubscription = { id in
        expect(id).toBe("sub_123")
        return .init(id: id, status: .active, customer: "cus_123", currentPeriodEnd: 0)
      }
    } operation: {
      try await HandleCheckoutSuccess.resolve(
        with: .init(stripeCheckoutSessionId: sessionId),
        in: context(admin)
      )
    }

    expect(output).toEqual(.success)
    let retrieved = try await self.db.find(admin.id)
    expect(retrieved.subscriptionId).toEqual(.init(rawValue: "sub_123"))
    expect(retrieved.subscriptionStatus).toEqual(.paid)
    expect(retrieved.subscriptionStatusExpiration).toEqual(Date.reference + .days(33))
  }

  func testCreatePendingAppConnection() async throws {
    let user = try await self.user()

    let output = try await withDependencies {
      $0.verificationCode.generate = { 1234 }
    } operation: {
      try await CreatePendingAppConnection.resolve(
        with: .init(userId: user.id),
        in: context(user.admin)
      )
    }

    expect(output).toEqual(.init(code: 1234))
  }

  func testGetAdminWithNotifications() async throws {
    let admin = try await self.admin(with: \.subscriptionStatus, of: .paid)
    let method = AdminVerifiedNotificationMethod(
      parentId: admin.id,
      config: .email(email: "blob@blob.com")
    )
    try await self.db.create(method)
    var notification = AdminNotification.random
    notification.parentId = admin.id
    notification.methodId = method.id
    try await self.db.create(notification)

    let output = try await GetAdmin.resolve(in: context(admin))

    expect(output).toEqual(
      .init(
        id: admin.id,
        email: admin.email.rawValue,
        subscriptionStatus: .paid,
        notifications: [
          .init(
            id: notification.id,
            trigger: notification.trigger,
            methodId: notification.methodId
          ),
        ],
        verifiedNotificationMethods: [.init(id: method.id, config: method.config)],
        hasAdminChild: false,
        monthlyPriceInDollars: 15
      )
    )
  }

  func testCreatePendingMethod_Text() async throws {
    let admin = try await self.admin()
    let uuids = MockUUIDs()
    let id = uuids[0]

    let output = try await withDependencies {
      $0.verificationCode.generate = { 987_654 }
      $0.uuid = .mock(uuids)
    } operation: {
      try await CreatePendingNotificationMethod.resolve(
        with: .text(phoneNumber: "+12345678901"),
        in: context(admin)
      )
    }

    expect(output).toEqual(.init(methodId: .init(id)))

    // verify no db record created
    let preConfirm = try? await self.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that text was sent
    expect(sent.texts).toEqual([
      .init(
        to: "+12345678901",
        message: "Your verification code is 987654"
      ),
    ])

    // submit the "confirm pending" mutation
    let confirmOuput = try await ConfirmPendingNotificationMethod.resolve(
      with: .init(id: .init(id), code: 987_654),
      in: context(admin)
    )

    expect(confirmOuput).toEqual(.success)

    // verify method now added to db w/ correct info
    let retrieved = try? await self.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(retrieved?.id.rawValue).toEqual(id)
    expect(retrieved?.parentId).toEqual(admin.id)
    expect(retrieved?.config).toEqual(.text(phoneNumber: "+12345678901"))
  }

  func testCreatePendingMethod_Slack() async throws {
    let admin = try await self.admin()
    let uuids = MockUUIDs()
    let id = uuids[0]

    let output = try await withDependencies {
      $0.verificationCode.generate = { 123_456 }
      $0.uuid = .mock(uuids)
    } operation: {
      try await CreatePendingNotificationMethod.resolve(
        with: .slack(channelId: "C123", channelName: "Foo", token: "xoxb-123"),
        in: context(admin)
      )
    }

    expect(output).toEqual(.init(methodId: .init(id)))

    // verify no db record created
    let preConfirm = try? await self.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that slack was sent
    expect(sent.slacks).toHaveCount(1)
    expect(sent.slacks[0].token).toBe("xoxb-123")
    expect(sent.slacks[0].message.channel).toBe("C123")
    expect(sent.slacks[0].message.text).toContain("123456")

    // submit the "confirm pending" mutation
    let confirmOuput = try await ConfirmPendingNotificationMethod.resolve(
      with: .init(id: .init(id), code: 123_456),
      in: context(admin)
    )

    expect(confirmOuput).toEqual(.success)

    // verify method now added to db w/ correct info
    let retrieved = try? await self.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(retrieved?.id.rawValue).toEqual(id)
    expect(retrieved?.parentId).toEqual(admin.id)
    expect(retrieved?.config)
      .toEqual(.slack(channelId: "C123", channelName: "Foo", token: "xoxb-123"))
  }

  func testCreatePendingMethod_Email() async throws {
    let admin = try await self.admin()
    let uuids = MockUUIDs()
    let id = uuids[0]

    let output = try await withDependencies {
      $0.verificationCode.generate = { 123_456 }
      $0.uuid = .mock(uuids)
    } operation: {
      try await CreatePendingNotificationMethod.resolve(
        with: .email(email: "blob@blob.com"),
        in: context(admin)
      )
    }

    expect(output).toEqual(.init(methodId: .init(id)))

    // verify no db record created
    let preConfirm = try? await self.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(preConfirm).toBeNil()

    // check that email was sent
    expect(sent.emails).toHaveCount(1)
    let email = try XCTUnwrap(sent.emails.first)
    expect(email.to).toEqual("blob@blob.com")
    expect(email.template).toBe("verify-notification-email")
    expect(email.templateModel["code"]!).toBe("123456")

    // submit the "confirm pending" mutation
    let confirmOuput = try await ConfirmPendingNotificationMethod.resolve(
      with: .init(id: .init(id), code: 123_456),
      in: context(admin)
    )

    expect(confirmOuput).toEqual(.success)

    // verify method now added to db w/ correct info
    let retrieved = try? await self.db.find(AdminVerifiedNotificationMethod.self, byId: id)
    expect(retrieved?.id.rawValue).toEqual(id)
    expect(retrieved?.parentId).toEqual(admin.id)
    expect(retrieved?.config).toEqual(.email(email: "blob@blob.com"))
  }

  func testCreateNewAdminNotification() async throws {
    let admin = try await self.admin()
    let method = try await self.db.create(
      AdminVerifiedNotificationMethod(
        parentId: admin.model.id,
        config: .email(email: "foo@bar.com")
      )
    )

    let output = try await SaveNotification.resolve(
      with: .init(id: .init(), isNew: true, methodId: method.id, trigger: .unlockRequestSubmitted),
      in: context(admin)
    )

    expect(output).toEqual(.success)
  }

  func testDeleteKeyNotifiesConnectedApps() async throws {
    let admin = try await self.admin().withKeychain()
    let output = try await DeleteEntity.resolve(
      with: .init(id: admin.key.id.rawValue, type: .key),
      in: context(admin)
    )
    expect(output).toEqual(.success)
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .usersWith(keychain: admin.keychain.id)),
    ])
  }

  func testDeletingLastUserDeviceDeletesDevice() async throws {
    let user = try await self.userWithDevice()
    _ = try await DeleteEntity.resolve(
      with: .init(id: user.device.id.rawValue, type: .userDevice),
      in: context(user.admin)
    )
    let retrieved = try? await self.db.find(user.adminDevice.id)
    expect(retrieved).toBeNil()
  }

  func testDeletingUserDeletesOrphanedDevice() async throws {
    let user = try await self.userWithDevice()
    _ = try await DeleteEntity.resolve(
      with: .init(id: user.id.rawValue, type: .user),
      in: context(user.admin)
    )
    let retrieved = try? await self.db.find(user.adminDevice.id)
    expect(retrieved).toBeNil()
  }

  func testDeletingAdminDeletesAdminAndCreatesDeletedEntity() async throws {
    try await self.db.delete(all: DeletedEntity.self)
    let admin = try await self.admin()

    _ = try await DeleteEntity.resolve(
      with: .init(id: admin.id.rawValue, type: .admin),
      in: context(admin)
    )

    let deleted = try await self.db.select(all: DeletedEntity.self)
    expect(deleted).toHaveCount(1)
    expect(deleted.first?.type).toEqual("Admin")
    expect(deleted.first?.reason).toEqual("self-deleted from use-case initial screen")
    expect(deleted.first!.data).toContain(admin.id.lowercased)
    await expect(try? self.db.find(admin.id)).toBeNil()
  }

  func testAdminCantDeleteOtherAdmin() async throws {
    let admin1 = try await self.admin()
    let admin2 = try await self.admin()

    try await expectErrorFrom { [weak self] in
      _ = try await DeleteEntity.resolve(
        with: .init(id: admin2.id.rawValue, type: .admin),
        in: self!.context(admin1)
      )
    }.toContain("Unauthorized")
  }

  func testLogDashboardEvent() async throws {
    try await self.db.delete(all: InterestingEvent.self)
    let admin = try await self.admin()

    let output = try await LogEvent.resolve(
      with: .init(eventId: "123", detail: "detail"),
      in: context(admin)
    )

    expect(output).toEqual(.success)
    let retrieved = try await self.db.select(all: InterestingEvent.self)
    expect(retrieved).toHaveCount(1)
    expect(retrieved.first?.eventId).toEqual("123")
    expect(retrieved.first?.kind).toEqual("event")
    expect(retrieved.first?.detail).toEqual("detail")
  }

  func testUpdateAdminNotification() async throws {
    let admin = try await self.admin()
    let email = try await self.db.create(
      AdminVerifiedNotificationMethod(
        parentId: admin.model.id,
        config: .email(email: "foo@bar.com")
      )
    )
    let text = try await self.db.create(
      AdminVerifiedNotificationMethod(
        parentId: admin.model.id,
        config: .text(phoneNumber: "1234567890")
      )
    )
    let notification = try await self.db.create(
      AdminNotification(
        parentId: admin.model.id,
        methodId: email.id,
        trigger: .unlockRequestSubmitted
      )
    )

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

    let retrieved = try await self.db.find(notification.id)
    expect(retrieved.methodId).toEqual(text.id)
    expect(retrieved.trigger).toEqual(.suspendFilterRequestSubmitted)
  }

  func testGetIdentifiedApps() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: AppCategory.self)
    try await self.db.delete(all: AppBundleId.self)

    let cat = try await self.db.create(AppCategory.random)
    var app = IdentifiedApp.random
    app.categoryId = cat.id
    try await self.db.create(app)
    var bundleId = AppBundleId.random
    bundleId.identifiedAppId = app.id
    try await self.db.create(bundleId)

    let output = try await GetIdentifiedApps.resolve(in: context(.mock))

    expect(output).toEqual([
      GetIdentifiedApps.App(
        id: app.id,
        name: app.name,
        slug: app.slug,
        launchable: app.launchable,
        bundleIds: [.init(from: bundleId)],
        category: .init(from: cat)
      ),
    ])
  }

  func testGetAdminKeychain() async throws {
    let admin = try await self.admin().withKeychain()
    let output = try await GetAdminKeychain.resolve(
      with: admin.keychain.id,
      in: context(admin)
    )
    let expected = GetAdminKeychain.Output(
      summary: KeychainSummary(
        id: admin.keychain.id,
        parentId: admin.id,
        name: admin.keychain.name,
        description: admin.keychain.description,
        isPublic: admin.keychain.isPublic,
        numKeys: 1
      ),
      keys: [.init(from: admin.key, keychainId: admin.keychain.id)]
    )

    expect(output).toEqual(expected)
  }

  func testGetAdminKeychains() async throws {
    let admin = try await self.admin().withKeychain()

    // child with keychain assigned
    let littleJimmy = try await self.db.create(
      User(parentId: admin.model.id, name: "Little Jimmy")
    )
    try await self.db.create(
      UserKeychain(childId: littleJimmy.id, keychainId: admin.keychain.id)
    )

    // child without keychain assigned
    let sally = try await self.db.create(
      User(parentId: admin.model.id, name: "Sally")
    )

    let output = try await GetAdminKeychains.resolve(in: context(admin))

    let expectedUsers = [
      GetAdminKeychains.Child(
        id: littleJimmy.id, name: littleJimmy.name
      ),
      GetAdminKeychains.Child(
        id: sally.id, name: sally.name
      ),
    ]

    let expectedKeychain = GetAdminKeychains.AdminKeychain(
      summary: KeychainSummary(
        id: admin.keychain.id,
        parentId: admin.id,
        name: admin.keychain.name,
        description: admin.keychain.description,
        isPublic: admin.keychain.isPublic,
        numKeys: 1
      ),
      children: [littleJimmy.id], // only littleJimmy, because sally doesn't have the keychain
      keys: [.init(from: admin.key, keychainId: admin.keychain.id)]
    )

    expect(output).toEqual(
      GetAdminKeychains.Output(
        keychains: [expectedKeychain],
        children: expectedUsers
      )
    )
  }

  func skip_testGetSelectableKeychains() async throws {
    try await self.db.delete(all: Key.self)
    try await self.db.delete(all: Keychain.self)

    let admin = try await self.admin().withKeychain { keychain, _ in
      keychain.isPublic = false
    }

    let otherAdmin = try await self.admin()
    var publicKeychain = Keychain.random
    publicKeychain.parentId = otherAdmin.id
    publicKeychain.isPublic = true
    try await self.db.create(publicKeychain)

    let output = try await GetSelectableKeychains.resolve(in: context(admin))

    await expect(output).toEqual(
      try .init(
        own: [.init(from: admin.keychain)],
        public: [.init(from: publicKeychain)]
      )
    )
  }

  func testSaveExistingKeychain() async throws {
    let admin = try await self.admin().withKeychain { keychain, _ in
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

    let retrieved = try await self.db.find(admin.keychain.id)
    expect(retrieved.name).toEqual("new name")
    expect(retrieved.description).toEqual("new description")
    expect(retrieved.isPublic).toEqual(false)
  }

  func testSaveNewKeychain() async throws {
    let admin = try await self.admin()
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

    let retrieved = try await self.db.find(id)
    expect(retrieved.name).toEqual("some name")
    expect(retrieved.description).toEqual("some description")
    expect(retrieved.isPublic).toEqual(false)
  }

  func testGetSuspendFilterRequest() async throws {
    let user = try await self.userWithDevice()
    var request = SuspendFilterRequest.random
    request.computerUserId = user.device.id
    try await self.db.create(request)

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
    let user = try await self.userWithDevice()

    var request = UnlockRequest.mock
    request.computerUserId = user.device.id
    request.status = .pending
    request.requestComment = "please dad"
    request.appBundleId = "com.rofl.biz"
    try await self.db.create(request)

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

    let userList =
      try await GetUserUnlockRequests
        .resolve(with: user.id, in: context(user.admin))
    expect(userList).toEqual([output])
  }

  func testLatestAppVersions() async throws {
    try await self.db.delete(all: Release.self)
    try await self.db.create([
      Release.mock {
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

    let output =
      try await LatestAppVersions
        .resolve(in: context(self.admin()))

    expect(output).toEqual(.init(stable: "2.2.0", beta: "2.5.2", canary: "3.0.0"))
  }
}
