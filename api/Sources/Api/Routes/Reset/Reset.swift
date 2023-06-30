import DuetSQL
import Gertie
import Vapor
import XCore

enum Reset {
  static func run() async throws {
    try await Current.db.deleteAll(Admin.self, force: true)
    try await createHtcPublicKeychain()
    try await AdminBetsy.create()
  }

  static func createHtcPublicKeychain() async throws {
    let jared = try await Current.db.create(Admin(
      email: "jared-htc-author" |> testEmail,
      password: try Bcrypt.hash("jared123")
    ))
    try await createKeychain(
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
    try await Current.db.create(AdminVerifiedNotificationMethod(adminId: admin.id, config: config))
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
    let keychain = try await Current.db.create(Keychain(
      id: id,
      authorId: adminId,
      name: name,
      isPublic: isPublic,
      description: description
    ))

    var keyRecords: [Key] = []
    for (index, key) in keys.enumerated() {
      keyRecords.append(Key(
        keychainId: keychain.id,
        key: key,
        comment: index & 3 == 0 ? "here is a lovely comment" : nil
      ))
    }
    try await Current.db.create(keyRecords)
    return keychain
  }

  static func createActivityItems(
    _ num: Int = Int.random(in: 15 ... 30),
    _ deviceId: Device.Id,
    subtractingDays: Int = 0,
    percentDeleted: Int = 0
  ) async throws {
    let items = Array(repeating: (), count: num)
      .map { createActivityItem(deviceId, subtractingDays: subtractingDays) }
    let keystrokeLines = try await Current.db.create(items.compactMap(\.right))
    let screenshots = try await Current.db.create(items.compactMap(\.left))

    var deleteBeforeIndex = percentDeleted == 0
      ? -1 : Int(Double(screenshots.count) * (Double(percentDeleted) / 100))

    for (index, var screenshot) in screenshots.enumerated() {
      if subtractingDays > 0 {
        try await screenshot.modifyCreatedAt(.subtracting(.days(subtractingDays) + .jitter))
      } else {
        try await screenshot.modifyCreatedAt(.subtracting(.jitter))
      }
      if index < deleteBeforeIndex {
        try await Current.db.delete(screenshot.id)
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
        try await Current.db.delete(keystroke.id)
      }
    }
  }

  private static func createActivityItem(
    _ deviceId: Device.Id,
    subtractingDays: Int = 0
  ) -> Either<Screenshot, KeystrokeLine> {
    if [1, 2, 3].shuffled().first! != 1 {
      let (width, height) = [(800, 600), (900, 600), (800, 500), (900, 500)].shuffled().first!
      return .left(Screenshot(
        deviceId: deviceId,
        url: "https://placekitten.com/\(width)/\(height)",
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
        deviceId: deviceId,
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
    guard let client = Current.db as? LiveClient else {
      throw Abort(.badRequest, reason: "Could not downcast Current.db to LiveClient")
    }

    try await client.sql.execute(
      """
      UPDATE \(raw: Self.tableName)
      SET \(col: .createdAt) = '\(raw: createdAt.isoString)'
      WHERE id = '\(raw: id.uuidString.lowercased())'
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
