import Dependencies
import DuetSQL
import Gertie
import Vapor
import XCore

enum AdminBetsy {
  enum Ids {
    static let betsy = Admin.Id.from("BE000000-0000-0000-0000-000000000000")
    static let jimmysId = User.Id.from("00000000-1111-4444-0000-000000000000")
    static let jimmysDevice = ComputerUser.Id.from("DD000000-1111-0000-0000-000000000000")
    static let sallysDevice = ComputerUser.Id.from("DD000000-2222-0000-0000-000000000000")
    static let suspendFilter = SuspendFilterRequest.Id.from("AA000000-1111-0000-0000-000000000000")
  }

  static func create() async throws {
    @Dependency(\.db) var db
    let betsy = try await db.create(Admin(
      id: Ids.betsy,
      email: "betsy-mcstandard" |> Reset.testEmail,
      password: Bcrypt.hash("betsy123"),
      subscriptionStatus: .trialing,
      subscriptionStatusExpiration: Date().advanced(by: .days(53)),
      subscriptionId: nil
    ))

    let email = try await Reset.createNotification(
      betsy,
      .email(email: betsy.email.rawValue)
    )

    try await db.create(AdminNotification(
      parentId: betsy.id,
      methodId: email.id,
      trigger: .unlockRequestSubmitted
    ))

    let text = try await Reset.createNotification(
      betsy,
      .text(phoneNumber: "+15555555555")
    )

    try await Reset.createNotification(
      betsy,
      .slack(channelId: "CQ1325FCA", channelName: "#Gertrude", token: "xoxb-123-456-789")
    )

    try await db.create(AdminNotification(
      parentId: betsy.id,
      methodId: text.id,
      trigger: .suspendFilterRequestSubmitted
    ))

    try await db.create(AdminToken(
      value: .init(rawValue: betsy.id.rawValue),
      parentId: betsy.id
    ))

    let (jimmy, sally, _) = try await createUsers(betsy)
    let (musicTheory, misc) = try await createKeychains(betsy)

    if let firstPublicKeychain = try? await Keychain.query()
      .where(.isPublic == true)
      .first(in: db) {
      try await db.create([
        UserKeychain(childId: jimmy.id, keychainId: firstPublicKeychain.id),
        UserKeychain(childId: sally.id, keychainId: firstPublicKeychain.id),
      ])
    }

    try await db.create([
      UserKeychain(childId: jimmy.id, keychainId: musicTheory.id),
      UserKeychain(childId: jimmy.id, keychainId: misc.id),
      UserKeychain(childId: sally.id, keychainId: misc.id),
    ])

    try await self.createUserActivity()
  }

  private static func createUsers(_ betsy: Admin) async throws -> (User, User, User) {
    @Dependency(\.db) var db
    let jimmy = try await db.create(User(
      id: Ids.jimmysId,
      parentId: betsy.id,
      name: "Little Jimmy",
      keyloggingEnabled: true,
      screenshotsEnabled: true
    ))

    let macAir = try await db.create(Device(
      parentId: betsy.id,
      customName: nil,
      filterVersion: "2.6.0",
      modelIdentifier: "Mac14,2",
      serialNumber: "JIMMY-AIR-123456"
    ))

    let computerUser = try await db.create(ComputerUser(
      childId: jimmy.id,
      computerId: macAir.id,
      isAdmin: false,
      appVersion: "2.6.0",
      username: "jimmy",
      fullUsername: "Jimmy McStandard",
      numericId: 502
    ))

    try await self.createTransientRequests(computerUser)

    let imac = try await db.create(Device(
      parentId: betsy.id,
      customName: nil,
      filterVersion: "2.6.0",
      modelIdentifier: "iMac19,2",
      serialNumber: "JIMMY-IMAC-123456"
    ))

    try await db.create(ComputerUser(
      id: Ids.jimmysDevice,
      childId: jimmy.id,
      computerId: imac.id,
      isAdmin: false,
      appVersion: "2.6.0",
      username: "jimmy",
      fullUsername: "Jimmy McStandard",
      numericId: 504
    ))

    let sally = try await db.create(User(
      parentId: betsy.id,
      name: "Sally",
      keyloggingEnabled: false,
      screenshotsEnabled: false
    ))

    let macbookPro = try await db.create(Device(
      parentId: betsy.id,
      customName: "dads mbp",
      filterVersion: "2.6.0",
      modelIdentifier: "MacBookPro18,1",
      serialNumber: "SALLY-MBP-123456"
    ))

    try await db.create(ComputerUser(
      id: Ids.sallysDevice,
      childId: sally.id,
      computerId: macbookPro.id,
      isAdmin: false,
      appVersion: "2.6.0",
      username: "sally",
      fullUsername: "Sally McStandard",
      numericId: 503
    ))

    // henry has no devices
    let henry = try await db.create(User(
      parentId: betsy.id,
      name: "Henry",
      keyloggingEnabled: true,
      screenshotsEnabled: false
    ))

    return (jimmy, sally, henry)
  }

  private static func createKeychains(_ betsy: Admin) async throws -> (Keychain, Keychain) {
    let musicTheory = try await Reset.createKeychain(
      adminId: betsy.id,
      name: "Jimmy's Music Theory",
      keys: [
        .anySubdomain(domain: .init("musictheory.com")!, scope: .webBrowsers),
        .domain(domain: .init("mixolydian.com")!, scope: .unrestricted),
        .skeleton(scope: .identifiedAppSlug("theory-tunes")),
      ]
    )
    let misc = try await Reset.createKeychain(
      adminId: betsy.id,
      name: "Misc McStandard Keys",
      keys: [
        .domain(domain: .init("stackunderflow.com")!, scope: .unrestricted),
        .domain(domain: .init("gitclub.com")!, scope: .webBrowsers),
        .anySubdomain(domain: .init("fruit-rollup.com")!, scope: .webBrowsers),
      ] + Array(repeating: (), count: 50).enumerated().map { index, _ in
        .anySubdomain(domain: .init("www.somesite-\(index + 1).com")!, scope: .webBrowsers)
      }
    )
    return (musicTheory, misc)
  }

  private static func createUserActivity() async throws {
    async let j1: Void = Reset.createActivityItems(
      109,
      Ids.jimmysDevice,
      subtractingDays: 0,
      percentDeleted: 0
    )
    async let j2: Void = Reset.createActivityItems(
      23,
      Ids.jimmysDevice,
      subtractingDays: 1,
      percentDeleted: 33
    )
    async let j3: Void = Reset.createActivityItems(
      8,
      Ids.jimmysDevice,
      subtractingDays: 2,
      percentDeleted: 100
    )
    async let s1: Void = Reset.createActivityItems(
      17,
      Ids.sallysDevice,
      percentDeleted: 0
    )

    _ = try await [j1, j2, j3, s1]
  }

  private static func createTransientRequests(_ computerUser: ComputerUser) async throws {
    @Dependency(\.db) var db
    try await db.create(UnlockRequest(
      computerUserId: computerUser.id,
      appBundleId: ".com.apple.Safari",
      url: "https://www.youtube.com/watch?v=123456789",
      hostname: "youtube.com",
      ipAddress: "234.423.32.2423",
      requestComment: "I want to watch a video",
      status: .pending
    ))

    try await db.create(UnlockRequest(
      computerUserId: computerUser.id,
      appBundleId: "BQR82RBBHL.com.tinyspeck.slackmacgap.helper",
      hostname: "someotherwebsite.com",
      ipAddress: "234.423.32.2423",
      requestComment: "Need this for my dinasours class, k thx",
      status: .pending
    ))

    try await db.create(SuspendFilterRequest(
      id: Ids.suspendFilter,
      computerUserId: computerUser.id,
      status: .pending,
      scope: .webBrowsers,
      requestComment: "I want to watch a video"
    ))
  }
}
