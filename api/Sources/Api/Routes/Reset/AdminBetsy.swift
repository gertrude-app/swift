import Gertie
import Vapor
import XCore

enum AdminBetsy {
  enum Ids {
    static let betsy = Admin.Id.from("BE000000-0000-0000-0000-000000000000")
    static let jimmysId = User.Id.from("00000000-1111-4444-0000-000000000000")
    static let jimmysDevice = UserDevice.Id.from("DD000000-1111-0000-0000-000000000000")
    static let sallysDevice = UserDevice.Id.from("DD000000-2222-0000-0000-000000000000")
    static let suspendFilter = SuspendFilterRequest.Id.from("AA000000-1111-0000-0000-000000000000")
  }

  static func create() async throws {
    let betsy = try await Current.db.create(Admin(
      id: Ids.betsy,
      email: "betsy-mcstandard" |> Reset.testEmail,
      password: try Bcrypt.hash("betsy123"),
      subscriptionStatus: .paid,
      subscriptionStatusExpiration: Date().advanced(by: .days(30)),
      subscriptionId: .init(rawValue: "sub_1LropYGKRdhETuKAE6gufq5J")
    ))

    let email = try await Reset.createNotification(
      betsy,
      .email(email: betsy.email.rawValue)
    )

    try await Current.db.create(AdminNotification(
      adminId: betsy.id,
      methodId: email.id,
      trigger: .unlockRequestSubmitted
    ))

    let text = try await Reset.createNotification(
      betsy,
      .text(phoneNumber: "555-555-5555")
    )

    try await Reset.createNotification(
      betsy,
      .slack(channelId: "CQ1325FCA", channelName: "#Gertrude", token: "xoxb-123-456-789")
    )

    try await Current.db.create(AdminNotification(
      adminId: betsy.id,
      methodId: text.id,
      trigger: .suspendFilterRequestSubmitted
    ))

    try await Current.db.create(AdminToken(
      value: .init(rawValue: betsy.id.rawValue),
      adminId: betsy.id
    ))

    let (jimmy, sally, _) = try await createUsers(betsy)
    let (musicTheory, misc) = try await createKeychains(betsy)

    try await Current.db.create([
      UserKeychain(userId: jimmy.id, keychainId: musicTheory.id),
      UserKeychain(userId: jimmy.id, keychainId: misc.id),
      UserKeychain(userId: jimmy.id, keychainId: Reset.Ids.htcKeychain),
      UserKeychain(userId: sally.id, keychainId: misc.id),
      UserKeychain(userId: sally.id, keychainId: Reset.Ids.htcKeychain),
    ])

    try await createUserActivity()
  }

  private static func createUsers(_ betsy: Admin) async throws -> (User, User, User) {
    let jimmy = try await Current.db.create(User(
      id: Ids.jimmysId,
      adminId: betsy.id,
      name: "Little Jimmy",
      keyloggingEnabled: true,
      screenshotsEnabled: true
    ))

    let macAir = try await Current.db.create(Device(
      adminId: betsy.id,
      customName: nil,
      modelIdentifier: "Mac14,2",
      serialNumber: "JIMMY-AIR-123456"
    ))

    let userDevice = try await Current.db.create(UserDevice(
      userId: jimmy.id,
      deviceId: macAir.id,
      appVersion: "2.1.0",
      username: "jimmy",
      fullUsername: "Jimmy McStandard",
      numericId: 502
    ))

    try await createTransientRequests(userDevice)

    let imac = try await Current.db.create(Device(
      adminId: betsy.id,
      customName: nil,
      modelIdentifier: "iMac19,2",
      serialNumber: "JIMMY-IMAC-123456"
    ))

    try await Current.db.create(UserDevice(
      id: Ids.jimmysDevice,
      userId: jimmy.id,
      deviceId: imac.id,
      appVersion: "2.1.0",
      username: "jimmy",
      fullUsername: "Jimmy McStandard",
      numericId: 504
    ))

    let sally = try await Current.db.create(User(
      adminId: betsy.id,
      name: "Sally",
      keyloggingEnabled: false,
      screenshotsEnabled: false
    ))

    let macbookPro = try await Current.db.create(Device(
      adminId: betsy.id,
      customName: "dads mbp",
      modelIdentifier: "MacBookPro18,1",
      serialNumber: "SALLY-MBP-123456"
    ))

    try await Current.db.create(UserDevice(
      id: Ids.sallysDevice,
      userId: sally.id,
      deviceId: macbookPro.id,
      appVersion: "2.1.0",
      username: "sally",
      fullUsername: "Sally McStandard",
      numericId: 503
    ))

    // henry has no devices
    let henry = try await Current.db.create(User(
      adminId: betsy.id,
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

  private static func createTransientRequests(_ userDevice: UserDevice) async throws {
    let nd1 = try await Current.db.create(NetworkDecision(
      userDeviceId: userDevice.id,
      verdict: .block,
      reason: .defaultNotAllowed,
      hostname: "youtube.com",
      ipAddress: "234.423.32.2423",
      url: "https://www.youtube.com/watch?v=123456789",
      appBundleId: ".com.apple.Safari",
      createdAt: Date()
    ))

    let nd2 = try await Current.db.create(NetworkDecision(
      userDeviceId: userDevice.id,
      verdict: .block,
      reason: .defaultNotAllowed,
      hostname: "someotherwebsite.com",
      ipAddress: "234.423.32.2423",
      appBundleId: "BQR82RBBHL.com.tinyspeck.slackmacgap.helper",
      createdAt: Date(subtractingDays: 1)
    ))

    try await Current.db.create(UnlockRequest(
      networkDecisionId: nd1.id,
      userDeviceId: userDevice.id,
      requestComment: "I want to watch a video",
      status: .pending
    ))

    try await Current.db.create(UnlockRequest(
      networkDecisionId: nd2.id,
      userDeviceId: userDevice.id,
      requestComment: "Need this for my dinasours class, k thx",
      status: .pending
    ))

    try await Current.db.create(SuspendFilterRequest(
      id: Ids.suspendFilter,
      userDeviceId: userDevice.id,
      status: .pending,
      scope: .webBrowsers,
      requestComment: "I want to watch a video"
    ))
  }
}
