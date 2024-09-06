import Dependencies
import DuetSQL
import Gertie
import Vapor
import XCore

enum Reset {
  static func run() async throws {
    @Dependency(\.db) var db
    try await db.deleteAll(Admin.self, force: true)
    try await self.createHtcPublicKeychain()
    try await AdminBetsy.create()
  }

  static func createHtcPublicKeychain() async throws {
    let jared = try await Admin(
      email: "jared-htc-author" |> self.testEmail,
      password: try Bcrypt.hash("jared123")
    ).create()
    try await self.createKeychain(
      id: Ids.htcKeychain,
      adminId: jared.id,
      name: "HTC",
      isPublic: true,
      description: "Keys for student's in Jared's How to Computer (HTC) class.",
      keys: [
        .anySubdomain(domain: .init("howtocomputer.link")!, scope: .unrestricted),
        .anySubdomain(domain: .init("tailwind.css")!, scope: .webBrowsers),
        .anySubdomain(domain: .init("vsassets.io")!, scope: .single(.identifiedAppSlug("vscode"))),
        .anySubdomain(
          domain: .init("executeprogram.com")!,
          scope: .single(.bundleId("com.apple.Safari"))
        ),
        .domain(domain: .init("friendslibrary.com")!, scope: .unrestricted),
        .domain(domain: .init("developer.mozilla.org")!, scope: .webBrowsers),
        .domain(domain: .init("nextjs.org")!, scope: .webBrowsers),
        .domain(domain: .init("www.snowpack.dev")!, scope: .webBrowsers),
        .domain(domain: .init("regexr.com")!, scope: .webBrowsers),
        .domain(domain: .init("api.netlify.com")!, scope: .unrestricted),
        .domain(domain: .init("registry.npmjs.org")!, scope: .single(.bundleId(".node"))),
        .skeleton(scope: .identifiedAppSlug("slack")),
        .skeleton(scope: .bundleId("Y48LQG59RS.com.sequelpro.SequelPro")),
        .ipAddress(ipAddress: .init("76.88.114.31")!, scope: .unrestricted),
      ]
    )
  }

  @discardableResult
  static func createNotification(
    _ admin: Admin,
    _ config: AdminVerifiedNotificationMethod.Config
  ) async throws -> AdminVerifiedNotificationMethod {
    try await AdminVerifiedNotificationMethod(adminId: admin.id, config: config).create()
  }

  static func testEmail(_ tag: String) -> EmailAddress {
    .init(rawValue: "82uii.\(tag)@inbox.testmail.app")
  }

  @discardableResult
  static func createKeychain(
    id: Keychain.Id = .init(),
    adminId: Admin.Id,
    name: String,
    isPublic: Bool = false,
    description: String? = nil,
    keys: [Gertie.Key] = []
  ) async throws -> Keychain {
    let keychain = try await Keychain(
      id: id,
      authorId: adminId,
      name: name,
      isPublic: isPublic,
      description: description
    ).create()

    var keyRecords: [Key] = []
    for (index, key) in keys.enumerated() {
      keyRecords.append(Key(
        keychainId: keychain.id,
        key: key,
        comment: index & 3 == 0 ? "here is a lovely comment" : nil
      ))
    }
    try await Key.create(keyRecords)
    return keychain
  }

  static func createActivityItems(
    _ num: Int = Int.random(in: 15 ... 30),
    _ deviceId: UserDevice.Id,
    subtractingDays: Int = 0,
    percentDeleted: Int = 0
  ) async throws {
    let items = Array(repeating: (), count: num)
      .map { createActivityItem(deviceId, subtractingDays: subtractingDays) }
    let keystrokeLines = try await items.compactMap(\.right).create()
    let screenshots = try await items.compactMap(\.left).create()

    var deleteBeforeIndex = percentDeleted == 0
      ? -1 : Int(Double(screenshots.count) * (Double(percentDeleted) / 100))

    for (index, var screenshot) in screenshots.enumerated() {
      if subtractingDays > 0 {
        try await screenshot.modifyCreatedAt(.subtracting(.days(subtractingDays) + .jitter))
      } else {
        try await screenshot.modifyCreatedAt(.subtracting(.jitter))
      }
      if index < deleteBeforeIndex {
        try await screenshot.delete()
      }
    }

    deleteBeforeIndex = percentDeleted == 0
      ? -1 : Int(Double(keystrokeLines.count) * (Double(percentDeleted) / 100))

    for (index, var keystroke) in keystrokeLines.enumerated() {
      if subtractingDays > 0 {
        try await keystroke.modifyCreatedAt(.subtracting(.days(subtractingDays) + .jitter))
      } else {
        try await keystroke.modifyCreatedAt(.subtracting(.jitter))
      }
      if index < deleteBeforeIndex {
        try await keystroke.delete()
      }
    }
  }

  private static func createActivityItem(
    _ userDeviceId: UserDevice.Id,
    subtractingDays: Int = 0
  ) -> Either<Screenshot, KeystrokeLine> {
    if [1, 2, 3].shuffled().first! != 1 {
      let (width, height) = [(800, 600), (900, 600), (800, 500), (900, 500)].shuffled().first!
      return .left(Screenshot(
        userDeviceId: userDeviceId,
        url: "https://fakeimg.pl/\(width)x\(height)/3e2a73/ffffff",
        width: width,
        height: height
      ))
    } else {
      let (app, line) = [
        ("XCode", "import Foundation"),
        ("VSCode", "let x: number = [33];"),
        ("Zoom", "why am I the only one in this meeting?"),
        ("Brave", "what is the average flight velocity of a sparrow?"),
        ("Notes", "dear diary,\ni know i haven't written in a long time.\nsorry!"),
      ].shuffled().first!
      return .right(KeystrokeLine(
        userDeviceId: userDeviceId,
        appName: app,
        line: line,
        createdAt: .init()
      ))
    }
  }

  enum Ids {
    static let htcKeychain = Keychain.Id.from("AAA00000-0000-0000-0000-000000000000")
  }
}

enum TimestampAdjustment {
  case subtracting(TimeInterval)
  case adding(TimeInterval)
  case exact(Date)
}

extension DuetSQL.Model where Self: HasCreatedAt {
  mutating func modifyCreatedAt(
    _ adjustment: TimestampAdjustment
  ) async throws {
    switch adjustment {
    case .subtracting(let interval):
      createdAt = createdAt.addingTimeInterval(-interval)
    case .adding(let interval):
      createdAt = createdAt.addingTimeInterval(interval)
    case .exact(let date):
      createdAt = date
    }

    @Dependency(\.db) var db
    guard let client = db as? PgClient else {
      throw Abort(.internalServerError, reason: "af72eb37")
    }

    try await client.db.execute(
      """
      UPDATE \(unsafeRaw: Self.tableName)
      SET \(col: .createdAt) = '\(unsafeRaw: createdAt.isoString)'
      WHERE id = '\(unsafeRaw: id.uuidString.lowercased())'
      """
    )
  }
}

extension Tagged where RawValue == UUID {
  static func from(_ uuidString: String) -> Self {
    .init(rawValue: .init(uuidString: uuidString) ?? .init())
  }
}

private extension TimeInterval {
  static var jitter: Self {
    .seconds(Int.random(in: 0 ... 120))
  }
}
