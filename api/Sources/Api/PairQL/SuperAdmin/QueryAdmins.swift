import DuetSQL
import Gertie
import PairQL

struct QueryAdmins: Pair {
  static var auth: ClientAuth = .superAdmin

  struct AdminData: PairOutput {
    struct Child: PairNestable {
      struct Installation: PairNestable {
        var userId: Int
        var appVersion: String
        var filterVersion: String
        var modelIdentifier: String
        var appReleaseChannel: ReleaseChannel
        var createdAt: Date
      }

      var name: String
      var keyloggingEnabled: Bool
      var screenshotsEnabled: Bool
      var numKeychains: Int
      var numKeys: Int
      var numActivityItems: Int
      var installations: [Installation]
      var createdAt: Date
    }

    var id: Admin.Id
    var email: EmailAddress
    var subscriptionId: Admin.SubscriptionId?
    var subscriptionStatus: Admin.SubscriptionStatus
    var numNotifications: Int
    var numKeychains: Int
    var children: [Child]
    var createdAt: Date
  }

  typealias Output = [AdminData]
}

// resolver

extension QueryAdmins: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {

    func expect<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) throws -> T {
      guard let value else {
        throw context.error(
          id: "30e6e410",
          type: .serverError,
          debugMessage: "unexpected nil for \(T.self) from \(file):\(line)"
        )
      }
      return value
    }

    let rows = try await Current.db.customQuery(AdminQuery.self)

    var installations: [UserDevice.Id: (AdminData.Child.Installation, User.Id)] = [:]
    for row in rows where row.userDeviceId != nil {
      let userDeviceId = try expect(row.userDeviceId)
      guard installations[userDeviceId] == nil else { continue }
      let installation = AdminData.Child.Installation(
        userId: try expect(row.numericId),
        appVersion: try expect(row.appVersion),
        filterVersion: row.filterVersion ?? "unknown",
        modelIdentifier: try expect(row.modelIdentifier),
        appReleaseChannel: try expect(row.appReleaseChannel),
        createdAt: try expect(row.userDeviceCreatedAt)
      )
      installations[userDeviceId] = (installation, try expect(row.userId))
    }

    var children: [User.Id: (AdminData.Child, Admin.Id)] = [:]
    for row in rows where row.userId != nil {
      let userId = try expect(row.userId)
      guard children[userId] == nil else { continue }
      let child = AdminData.Child(
        name: try expect(row.userName),
        keyloggingEnabled: try expect(row.keyloggingEnabled),
        screenshotsEnabled: try expect(row.screenshotsEnabled),
        numKeychains: row.userKeychainCount,
        numKeys: row.numKeys,
        numActivityItems: row.keystrokeCount + row.screenshotCount,
        installations: [],
        createdAt: try expect(row.userCreatedAt)
      )
      children[userId] = (child, row.adminId)
    }

    for (installation, userId) in installations.values {
      let _ = try expect(children[userId])
      children[userId]!.0.installations.append(installation)
    }

    var admins: [Admin.Id: AdminData] = [:]
    for row in rows {
      guard admins[row.adminId] == nil else { continue }
      guard !isTestAddress(row.email.rawValue) else { continue }
      admins[row.adminId] = .init(
        id: row.adminId,
        email: row.email,
        subscriptionId: row.subscriptionId,
        subscriptionStatus: row.subscriptionStatus,
        numNotifications: row.numNotifications,
        numKeychains: row.numKeychains,
        children: [],
        createdAt: row.adminCreatedAt
      )
    }

    for (child, adminId) in children.values {
      let _ = try expect(admins[adminId])
      admins[adminId]!.children.append(child)
    }

    return Array(admins.values)
  }
}

// query

struct AdminQuery: CustomQueryable {
  static func query(numBindings: Int) -> String {
    """
    SELECT
        admins.id AS admin_id,
        admins.email,
        admins.subscription_id,
        admins.subscription_status,
        admins.created_at AS admin_created_at,
        COUNT(DISTINCT CASE WHEN keychains.deleted_at IS NULL THEN keychains.id END) AS num_keychains,
        COALESCE(an.num_notifications, 0) AS num_notifications,
        users.id AS user_id,
        users.name as user_name,
        users.keylogging_enabled,
        users.screenshots_enabled,
        COALESCE(screenshot_count, 0) AS screenshot_count,
        COALESCE(keystroke_count, 0) AS keystroke_count,
        COUNT(DISTINCT user_keychain.keychain_id) AS user_keychain_count,
        COUNT(DISTINCT CASE WHEN keys.deleted_at IS NULL THEN keys.id END) AS num_keys,
        user_devices.numeric_id,
        user_devices.app_version,
        user_devices.created_at AS user_device_created_at,
        user_devices.id AS user_device_id,
        users.created_at AS user_created_at,
        devices.filter_version,
        devices.model_identifier,
        devices.app_release_channel,
        devices.id AS device_id
    FROM admins
    LEFT JOIN keychains ON admins.id = keychains.author_id AND keychains.deleted_at IS NULL
    LEFT JOIN (
        SELECT admin_id, COUNT(DISTINCT id) AS num_notifications
        FROM admin_notifications
        GROUP BY admin_id
    ) AS an ON admins.id = an.admin_id
    LEFT JOIN users ON admins.id = users.admin_id
    LEFT JOIN (
        SELECT ud.user_id, COUNT(DISTINCT s.id) AS screenshot_count
        FROM screenshots s
        JOIN user_devices ud ON s.user_device_id = ud.id
        WHERE s.deleted_at IS NULL
        GROUP BY ud.user_id
    ) AS s ON users.id = s.user_id
    LEFT JOIN (
        SELECT ud.user_id, COUNT(DISTINCT kl.id) AS keystroke_count
        FROM keystroke_lines kl
        JOIN user_devices ud ON kl.user_device_id = ud.id
        WHERE kl.deleted_at IS NULL
        GROUP BY ud.user_id
    ) AS k ON users.id = k.user_id
    LEFT JOIN user_devices ON users.id = user_devices.user_id
    LEFT JOIN devices ON user_devices.device_id = devices.id
    LEFT JOIN user_keychain ON users.id = user_keychain.user_id
    LEFT JOIN keys ON user_keychain.keychain_id = keys.keychain_id
    WHERE
      users.deleted_at IS NULL AND
      admins.email NOT LIKE '%.smoke-test-%'
    GROUP BY
      admins.id,
      admins.email,
      admins.subscription_id,
      admins.subscription_status,
      admins.created_at,
      users.id,
      users.name,
      users.keylogging_enabled,
      users.screenshots_enabled,
      an.num_notifications,
      screenshot_count,
      keystroke_count,
      user_devices.numeric_id,
      user_devices.app_version,
      user_devices.created_at,
      user_devices.id,
      users.created_at,
      devices.filter_version,
      devices.model_identifier,
      devices.app_release_channel,
      devices.id
    ORDER BY admins.id;
    """
  }

  // admin
  let adminId: Admin.Id
  let email: EmailAddress
  let subscriptionId: Admin.SubscriptionId?
  let subscriptionStatus: Admin.SubscriptionStatus
  let numNotifications: Int
  let numKeychains: Int
  let adminCreatedAt: Date

  // child
  let userId: User.Id?
  let userName: String?
  let keyloggingEnabled: Bool?
  let screenshotsEnabled: Bool?
  let userKeychainCount: Int
  let numKeys: Int
  let screenshotCount: Int
  let keystrokeCount: Int
  let userCreatedAt: Date?

  // installation
  let userDeviceId: UserDevice.Id?
  let numericId: Int?
  let appVersion: String?
  let filterVersion: String?
  let modelIdentifier: String?
  let appReleaseChannel: ReleaseChannel?
  let userDeviceCreatedAt: Date?
}
