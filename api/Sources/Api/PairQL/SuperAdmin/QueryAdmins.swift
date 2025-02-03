import DuetSQL
import Gertie
import PairQL
import PostgresKit

struct QueryAdmins: Pair {
  static let auth: ClientAuth = .superAdmin

  struct AdminData: PairOutput {
    struct Child: PairNestable {
      struct Installation: PairNestable {
        var userId: Int
        var appVersion: String
        var filterVersion: String
        var modelIdentifier: String
        var appReleaseChannel: ReleaseChannel
        var osVersionNumber: String?
        var osVersionName: String?
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
    var hasGclid: Bool
    var email: EmailAddress
    var subscriptionId: Admin.SubscriptionId?
    var subscriptionStatus: Admin.SubscriptionStatus
    var abTestVariant: String?
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

    let rows = try await context.db.customQuery(AdminQuery.self)

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
        osVersionNumber: row.osVersion?.description,
        osVersionName: osVersionName(row.osVersion),
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
        hasGclid: row.hasGclid,
        email: row.email,
        subscriptionId: row.subscriptionId,
        subscriptionStatus: row.subscriptionStatus,
        abTestVariant: row.abTestVariant,
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

func osVersionName(_ osVersion: Semver?) -> String? {
  switch osVersion?.major {
  case 10:
    return "Catalina"
  case 11:
    return "Big Sur"
  case 12:
    return "Monterey"
  case 13:
    return "Ventura"
  case 14:
    return "Sonoma"
  case 15:
    return "Sequoia"
  case nil:
    return nil
  default:
    return "(Unknown \(osVersion?.major ?? 0))"
  }
}

// query

struct AdminQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT
      parent.parents.id AS admin_id,
      parent.parents.email,
      parent.parents.gclid IS NOT NULL AS has_gclid,
      parent.parents.subscription_id,
      parent.parents.subscription_status,
      parent.parents.ab_test_variant,
      parent.parents.created_at AS admin_created_at,
      COUNT(DISTINCT parent.keychains.id) AS num_keychains,
      COALESCE(an.num_notifications, 0) AS num_notifications,
      parent.children.id AS user_id,
      parent.children.name as user_name,
      parent.children.keylogging_enabled,
      parent.children.screenshots_enabled,
      COALESCE(screenshot_count, 0) AS screenshot_count,
      COALESCE(keystroke_count, 0) AS keystroke_count,
      COUNT(DISTINCT child.keychains.keychain_id) AS user_keychain_count,
      COUNT(DISTINCT CASE WHEN parent.keys.deleted_at IS NULL THEN parent.keys.id END) AS num_keys,
      child.computer_users.numeric_id,
      child.computer_users.app_version,
      child.computer_users.created_at AS user_device_created_at,
      child.computer_users.id AS user_device_id,
      parent.children.created_at AS user_created_at,
      parent.computers.filter_version,
      parent.computers.model_identifier,
      parent.computers.app_release_channel,
      parent.computers.os_version,
      parent.computers.id AS device_id
    FROM parent.parents
    LEFT JOIN parent.keychains ON parent.parents.id = parent.keychains.parent_id
    LEFT JOIN (
      SELECT parent_id, COUNT(DISTINCT id) AS num_notifications
      FROM parent.notifications
      GROUP BY parent_id
    ) AS an ON parent.parents.id = an.parent_id
    LEFT JOIN parent.children ON parent.parents.id = parent.children.parent_id
    LEFT JOIN (
      SELECT ud.child_id, COUNT(DISTINCT s.id) AS screenshot_count
      FROM macapp.screenshots s
      JOIN child.computer_users ud ON s.computer_user_id = ud.id
      WHERE s.deleted_at IS NULL
      GROUP BY ud.child_id
    ) AS s ON parent.children.id = s.child_id
    LEFT JOIN (
      SELECT ud.child_id, COUNT(DISTINCT kl.id) AS keystroke_count
      FROM macapp.keystroke_lines kl
      JOIN child.computer_users ud ON kl.computer_user_id = ud.id
      WHERE kl.deleted_at IS NULL
      GROUP BY ud.child_id
    ) AS k ON parent.children.id = k.child_id
    LEFT JOIN child.computer_users ON parent.children.id = child.computer_users.child_id
    LEFT JOIN parent.computers ON child.computer_users.computer_id = parent.computers.id
    LEFT JOIN child.keychains ON parent.children.id = child.keychains.child_id
    LEFT JOIN parent.keys ON child.keychains.keychain_id = parent.keys.keychain_id
    WHERE
      parent.parents.email NOT LIKE '%.smoke-test-%'
    GROUP BY
      parent.parents.id,
      parent.parents.email,
      parent.parents.subscription_id,
      parent.parents.subscription_status,
      parent.parents.created_at,
      parent.children.id,
      parent.children.name,
      parent.children.keylogging_enabled,
      parent.children.screenshots_enabled,
      an.num_notifications,
      screenshot_count,
      keystroke_count,
      child.computer_users.numeric_id,
      child.computer_users.app_version,
      child.computer_users.created_at,
      child.computer_users.id,
      parent.children.created_at,
      parent.computers.filter_version,
      parent.computers.model_identifier,
      parent.computers.app_release_channel,
      parent.computers.os_version,
      parent.computers.id;
    """)
  }

  // admin
  let adminId: Admin.Id
  let hasGclid: Bool
  let email: EmailAddress
  let subscriptionId: Admin.SubscriptionId?
  let subscriptionStatus: Admin.SubscriptionStatus
  let abTestVariant: String?
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
  let osVersion: Semver?
  let userDeviceCreatedAt: Date?
}
