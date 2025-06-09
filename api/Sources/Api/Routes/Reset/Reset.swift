import Dependencies
import DuetSQL
import Gertie
import Vapor
import XCore

enum Reset {
  static func run() async throws {
    @Dependency(\.db) var db
    try await Parent.query()
      .where(.id != Parent.Id.stagingPublicKeychainOwner)
      .delete(in: db)
    try await AdminBetsy.create()
  }

  static func ensurePublicKeychainOwner() async throws {
    @Dependency(\.db) var db
    let existing = try? await db.find(Parent.Id.stagingPublicKeychainOwner)
    if existing == nil {
      try await db.create(Parent(
        id: .stagingPublicKeychainOwner,
        email: "public-keychain-owner" |> self.testEmail,
        password: Bcrypt.hash("\(UUID())")
      ))
    }
  }

  @discardableResult
  static func createNotification(
    _ admin: Parent,
    _ config: Parent.NotificationMethod.Config
  ) async throws -> Parent.NotificationMethod {
    @Dependency(\.db) var db
    return try await db.create(Parent.NotificationMethod(parentId: admin.id, config: config))
  }

  static func testEmail(_ tag: String) -> EmailAddress {
    .init(rawValue: "82uii.\(tag)@inbox.testmail.app")
  }

  @discardableResult
  static func createKeychain(
    id: Keychain.Id = .init(),
    adminId: Parent.Id,
    name: String,
    isPublic: Bool = false,
    description: String? = nil,
    keys: [Gertie.Key] = []
  ) async throws -> Keychain {
    @Dependency(\.db) var db
    let keychain = try await db.create(Keychain(
      id: id,
      parentId: adminId,
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
    try await db.create(keyRecords)
    return keychain
  }

  static func createActivityItems(
    _ num: Int = Int.random(in: 15 ... 30),
    _ deviceId: ComputerUser.Id,
    subtractingDays: Int = 0,
    percentDeleted: Int = 0
  ) async throws {
    @Dependency(\.db) var db
    let items = Array(repeating: (), count: num)
      .map { self.createActivityItem(deviceId, subtractingDays: subtractingDays) }
    let keystrokeLines = try await db.create(items.compactMap(\.right))
    let screenshots = try await db.create(items.compactMap(\.left))

    var deleteBeforeIndex = percentDeleted == 0
      ? -1 : Int(Double(screenshots.count) * (Double(percentDeleted) / 100))

    for (index, var screenshot) in screenshots.enumerated() {
      if subtractingDays > 0 {
        try await screenshot.modifyCreatedAt(.subtracting(.days(subtractingDays) + .jitter))
      } else {
        try await screenshot.modifyCreatedAt(.subtracting(.jitter))
      }
      if index < deleteBeforeIndex {
        try await db.delete(screenshot)
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
        try await db.delete(keystroke)
      }
    }
  }

  private static func createActivityItem(
    _ userDeviceId: ComputerUser.Id,
    subtractingDays: Int = 0
  ) -> Either<Screenshot, KeystrokeLine> {
    if [1, 2, 3].shuffled().first! != 1 {
      let (width, height) = [(800, 600), (900, 600), (800, 500), (900, 500)].shuffled().first!
      let webAssetsUrl = "https://gertrude-web-assets.nyc3.digitaloceanspaces.com"
      return .left(Screenshot(
        computerUserId: userDeviceId,
        url: "\(webAssetsUrl)/placeholders-imgs/\(width)x\(height).png",
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
        computerUserId: userDeviceId,
        appName: app,
        line: line,
        createdAt: .init()
      ))
    }
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
      UPDATE \(unsafeRaw: Self.qualifiedTableName)
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
