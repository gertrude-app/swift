import DuetSQL
import Gertie
import GertieIOS

extension DashAnnouncement: Model {
  public static let schemaName = "parent"
  public static let tableName = "dash_announcements"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .icon: .varchar(self.icon)
    case .html: .string(self.html)
    case .learnMoreUrl: .varchar(self.learnMoreUrl)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .icon: .varchar(self.icon),
      .html: .string(self.html),
      .learnMoreUrl: .varchar(self.learnMoreUrl),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension IOSApp.BlockRule: Model {
  public static let schemaName = "iosapp"
  public static let tableName = "block_rules"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .vendorId: .uuid(self.vendorId)
    case .rule: .json(self.rule.toPostgresJson)
    case .groupId: .uuid(self.groupId)
    case .comment: .string(self.comment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .vendorId: .uuid(self.vendorId),
      .rule: .json(self.rule.toPostgresJson),
      .groupId: .uuid(self.groupId),
      .comment: .string(self.comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IOSApp.SuspendFilterRequest: Model {
  public static let schemaName = "iosapp"
  public static let tableName = "suspend_filter_requests"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .status: .enum(self.status)
    case .duration: .int(self.duration.rawValue)
    case .requestComment: .string(self.requestComment)
    case .responseComment: .string(self.responseComment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .status: .enum(self.status),
      .duration: .int(self.duration.rawValue),
      .requestComment: .string(self.requestComment),
      .responseComment: .string(self.responseComment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IOSApp.Token: Model {
  public static let schemaName = "child"
  public static let tableName = "iosapp_tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IOSApp.Device: Model {
  public static let schemaName = "child"
  public static let tableName = "ios_devices"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .vendorId: .uuid(self.vendorId)
    case .deviceType: .string(self.deviceType)
    case .appVersion: .string(self.appVersion)
    case .iosVersion: .string(self.iosVersion)
    case .webPolicy: .string(self.webPolicy)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .vendorId: .uuid(self.vendorId),
      .deviceType: .string(self.deviceType),
      .appVersion: .string(self.appVersion),
      .iosVersion: .string(self.iosVersion),
      .webPolicy: .string(self.webPolicy),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension GertieIOS.BlockRule: @retroactive PostgresJsonable {}

extension Parent: Model {
  public typealias ColumnName = CodingKeys
  public static let schemaName = "parent"
  public static let tableName = "parents"

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self.self)
    case .email: .string(self.email.rawValue)
    case .password: .string(self.password)
    case .subscriptionId: .string(self.subscriptionId?.rawValue)
    case .subscriptionStatus: .enum(self.subscriptionStatus)
    case .subscriptionStatusExpiration: .date(self.subscriptionStatusExpiration)
    case .gclid: .string(self.gclid)
    case .abTestVariant: .string(self.abTestVariant)
    case .monthlyPrice: .int(self.monthlyPrice.rawValue)
    case .trialPeriodDays: .int(self.trialPeriodDays)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .email: .string(email.rawValue),
      .password: .string(password),
      .subscriptionId: .string(subscriptionId?.rawValue),
      .subscriptionStatus: .enum(subscriptionStatus),
      .subscriptionStatusExpiration: .date(subscriptionStatusExpiration),
      .gclid: .string(gclid),
      .abTestVariant: .string(abTestVariant),
      .monthlyPrice: .int(monthlyPrice.rawValue),
      .trialPeriodDays: .int(trialPeriodDays),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Parent.Notification: Model {
  public static let schemaName = "parent"
  public static let tableName = "notifications"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .methodId: .uuid(self.methodId)
    case .trigger: .enum(self.trigger)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .methodId: .uuid(self.methodId),
      .trigger: .enum(self.trigger),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension Parent.DashToken: Model {
  public static let tableName = "dash_tokens"
  public static let schemaName = "parent"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension Parent.NotificationMethod.Config: PostgresJsonable {}

extension Parent.NotificationMethod: Model {
  public static let schemaName = "parent"
  public static let tableName = "notification_methods"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .config: .json(self.config.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .config: .json(self.config.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AppCategory: Model {
  public static let schemaName = "macos"
  public static let tableName = "app_categories"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .name: .string(self.name)
    case .slug: .string(self.slug)
    case .description: .string(self.description)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .name: .string(self.name),
      .slug: .string(self.slug),
      .description: .string(self.description),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension AppBundleId: Model {
  public static let schemaName = "macos"
  public static let tableName = "app_bundle_ids"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .bundleId: .string(self.bundleId)
    case .identifiedAppId: .uuid(self.identifiedAppId)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(self.bundleId),
      .identifiedAppId: .uuid(self.identifiedAppId),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension UserBlockedApp: Model {
  public static let schemaName = "child"
  public static let tableName = "blocked_mac_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .identifier: .string(self.identifier)
    case .childId: .uuid(self.childId)
    case .schedule: .json(self.schedule?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .identifier: .string(self.identifier),
      .childId: .uuid(self.childId),
      .schedule: .json(self.schedule?.toPostgresJson),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension ComputerUser: Model {
  public static let schemaName = "child"
  public static let tableName = "computer_users"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerId: .uuid(self.computerId)
    case .childId: .uuid(self.childId)
    case .isAdmin: .bool(self.isAdmin)
    case .appVersion: .string(self.appVersion)
    case .fullUsername: .string(self.fullUsername)
    case .numericId: .int(self.numericId)
    case .username: .string(self.username)
    case .updatedAt: .date(self.updatedAt)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .computerId: .uuid(self.computerId),
      .appVersion: .string(self.appVersion),
      .username: .string(self.username),
      .fullUsername: .string(self.fullUsername),
      .isAdmin: .bool(self.isAdmin),
      .numericId: .int(self.numericId),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Computer: Model {
  public static let schemaName = "parent"
  public static let tableName = "computers"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .customName: .string(self.customName)
    case .modelIdentifier: .string(self.modelIdentifier)
    case .serialNumber: .string(self.serialNumber)
    case .appReleaseChannel: .enum(self.appReleaseChannel)
    case .filterVersion: .varchar(self.filterVersion?.string)
    case .osVersion: .varchar(self.osVersion?.string)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .customName: .string(self.customName),
      .modelIdentifier: .string(self.modelIdentifier),
      .serialNumber: .string(self.serialNumber),
      .appReleaseChannel: .enum(self.appReleaseChannel),
      .filterVersion: .varchar(self.filterVersion?.string),
      .osVersion: .varchar(self.osVersion?.string),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IdentifiedApp: Model {
  public static let schemaName = "macos"
  public static let tableName = "identified_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .categoryId: .uuid(self.categoryId)
    case .name: .string(self.name)
    case .slug: .string(self.slug)
    case .launchable: .bool(self.launchable)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .categoryId: .uuid(self.categoryId),
      .name: .string(self.name),
      .slug: .string(self.slug),
      .launchable: .bool(self.launchable),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Keychain: Model {
  public static let schemaName = "parent"
  public static let tableName = "keychains"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .name: .string(self.name)
    case .description: .string(self.description)
    case .warning: .string(self.warning)
    case .isPublic: .bool(self.isPublic)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .name: .string(self.name),
      .description: .string(self.description),
      .warning: .string(self.warning),
      .isPublic: .bool(self.isPublic),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Gertie.Key: @retroactive PostgresJsonable {}

extension Key: Model {
  public static let schemaName = "parent"
  public static let tableName = "keys"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .keychainId: .uuid(self.keychainId)
    case .key: .json(self.key.toPostgresJson)
    case .comment: .string(self.comment)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .keychainId: .uuid(self.keychainId),
      .key: .json(self.key.toPostgresJson),
      .comment: .string(self.comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension KeystrokeLine: Model {
  public static let schemaName = "macapp"
  public static let tableName = "keystroke_lines"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .appName: .string(self.appName)
    case .line: .string(self.line)
    case .filterSuspended: .bool(self.filterSuspended)
    case .flagged: .date(self.flagged)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .appName: .string(self.appName),
      .line: .string(self.line),
      .filterSuspended: .bool(self.filterSuspended),
      .flagged: .date(self.flagged),
      .createdAt: .date(self.createdAt),
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension Release: Model {
  public static let schemaName = "macapp"
  public static let tableName = "releases"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .semver: .string(self.semver)
    case .channel: .enum(self.channel)
    case .signature: .string(self.signature)
    case .length: .int(self.length)
    case .revision: .string(self.revision.rawValue)
    case .requirementPace: .int(self.requirementPace)
    case .notes: .string(self.notes)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .semver: .string(self.semver),
      .channel: .enum(self.channel),
      .signature: .string(self.signature),
      .length: .int(self.length),
      .revision: .string(self.revision.rawValue),
      .requirementPace: .int(self.requirementPace),
      .notes: .string(self.notes),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Screenshot: Model {
  public static let schemaName = "child"
  public static let tableName = "screenshots"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .iosDeviceId: .uuid(self.iosDeviceId)
    case .url: .string(self.url)
    case .width: .int(self.width)
    case .height: .int(self.height)
    case .filterSuspended: .bool(self.filterSuspended)
    case .flagged: .date(self.flagged)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .iosDeviceId: .uuid(self.iosDeviceId),
      .url: .string(self.url),
      .width: .int(self.width),
      .height: .int(self.height),
      .filterSuspended: .bool(self.filterSuspended),
      .flagged: .date(self.flagged),
      .createdAt: .date(self.createdAt),
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension AppScope: @retroactive PostgresJsonable {}

extension MacApp.SuspendFilterRequest: Model {
  public static let schemaName = "macapp"
  public static let tableName = "suspend_filter_requests"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .status: .enum(self.status)
    case .scope: .json(self.scope.toPostgresJson)
    case .duration: .int(self.duration.rawValue)
    case .requestComment: .string(self.requestComment)
    case .responseComment: .string(self.responseComment)
    case .extraMonitoring: .string(self.extraMonitoring)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .status: .enum(self.status),
      .scope: .json(self.scope.toPostgresJson),
      .duration: .int(self.duration.rawValue),
      .requestComment: .string(self.requestComment),
      .responseComment: .string(self.responseComment),
      .extraMonitoring: .string(self.extraMonitoring),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension UnlockRequest: Model {
  public static let schemaName = "macapp"
  public static let tableName = "unlock_requests"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .computerUserId: .uuid(self.computerUserId)
    case .status: .enum(self.status)
    case .requestComment: .string(self.requestComment)
    case .responseComment: .string(self.responseComment)
    case .appBundleId: .string(self.appBundleId)
    case .url: .string(self.url)
    case .hostname: .string(self.hostname)
    case .ipAddress: .string(self.ipAddress)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .computerUserId: .uuid(self.computerUserId),
      .status: .enum(self.status),
      .requestComment: .string(self.requestComment),
      .responseComment: .string(self.responseComment),
      .appBundleId: .string(self.appBundleId),
      .url: .string(self.url),
      .hostname: .string(self.hostname),
      .ipAddress: .string(self.ipAddress),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Child: Model {
  public static let schemaName = "parent"
  public static let tableName = "children"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .name: .string(self.name)
    case .keyloggingEnabled: .bool(self.keyloggingEnabled)
    case .screenshotsEnabled: .bool(self.screenshotsEnabled)
    case .screenshotsResolution: .int(self.screenshotsResolution)
    case .screenshotsFrequency: .int(self.screenshotsFrequency)
    case .showSuspensionActivity: .bool(self.showSuspensionActivity)
    case .downtime: .json(self.downtime?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .name: .string(self.name),
      .keyloggingEnabled: .bool(self.keyloggingEnabled),
      .screenshotsEnabled: .bool(self.screenshotsEnabled),
      .screenshotsResolution: .int(self.screenshotsResolution),
      .screenshotsFrequency: .int(self.screenshotsFrequency),
      .showSuspensionActivity: .bool(self.showSuspensionActivity),
      .downtime: .json(self.downtime?.toPostgresJson),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension ChildKeychain: Model {
  public static let schemaName = "child"
  public static let tableName = "keychains"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .keychainId: .uuid(self.keychainId)
    case .schedule: .json(self.schedule?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .keychainId: .uuid(self.keychainId),
      .schedule: .json(self.schedule?.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension RuleSchedule: @retroactive PostgresJsonable {}
extension PlainTimeWindow: @retroactive PostgresJsonable {}

extension MacAppToken: Model {
  public static let schemaName = "child"
  public static let tableName = "macapp_tokens"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .childId: .uuid(self.childId)
    case .computerUserId: .uuid(self.computerUserId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .childId: .uuid(self.childId),
      .computerUserId: .uuid(self.computerUserId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension InterestingEvent: Model {
  public static let schemaName = "system"
  public static let tableName = "interesting_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .kind: .string(self.kind)
    case .context: .string(self.context)
    case .computerUserId: .uuid(self.computerUserId)
    case .parentId: .uuid(self.parentId)
    case .detail: .string(self.detail)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(self.eventId),
      .kind: .string(self.kind),
      .context: .string(self.context),
      .computerUserId: .uuid(self.computerUserId),
      .parentId: .uuid(self.parentId),
      .detail: .string(self.detail),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension StripeEvent: Model {
  public static let schemaName = "system"
  public static let tableName = "stripe_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .json: .string(self.json)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .json: .string(self.json),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension DeletedEntity: Model {
  public static let schemaName = "system"
  public static let tableName = "deleted_entities"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .type: .string(self.type)
    case .reason: .string(self.reason)
    case .data: .string(self.data)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .type: .string(self.type),
      .reason: .string(self.reason),
      .data: .string(self.data),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension Browser: Model {
  public static let schemaName = "macos"
  public static let tableName = "browsers"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .match: .json(self.match.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .match: .json(self.match.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension UnidentifiedApp: Model {
  public static let schemaName = "macos"
  public static let tableName = "unidentified_apps"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .bundleId: .string(self.bundleId)
    case .bundleName: .string(self.bundleName)
    case .localizedName: .string(self.localizedName)
    case .launchable: .bool(self.launchable)
    case .count: .int(self.count)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(self.bundleId),
      .bundleName: .string(self.bundleName),
      .localizedName: .string(self.localizedName),
      .launchable: .bool(self.launchable),
      .count: .int(self.count),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension BrowserMatch: @retroactive PostgresJsonable {}

extension SecurityEvent: Model {
  public static let schemaName = "system"
  public static let tableName = "security_events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .parentId: .uuid(self.parentId)
    case .computerUserId: .uuid(self.computerUserId)
    case .event: .string(self.event)
    case .detail: .string(self.detail)
    case .ipAddress: .string(self.ipAddress)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .parentId: .uuid(self.parentId),
      .computerUserId: .uuid(self.computerUserId),
      .event: .string(self.event),
      .detail: .string(self.detail),
      .ipAddress: .string(self.ipAddress),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension IOSApp.BlockGroup: Model {
  public static let schemaName = "iosapp"
  public static let tableName = "block_groups"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .name: .string(self.name)
    case .description: .string(self.description)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .name: .string(self.name),
      .description: .string(self.description),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension IOSApp.DeviceBlockGroup: Model {
  public static let schemaName = "iosapp"
  public static let tableName = "device_block_groups"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .blockGroupId: .uuid(self.blockGroupId)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .blockGroupId: .uuid(self.blockGroupId),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension IOSApp.WebPolicyDomain: Model {
  public static let schemaName = "iosapp"
  public static let tableName = "web_policy_domains"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .domain: .string(self.domain)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .deviceId: .uuid(self.deviceId),
      .domain: .string(self.domain),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension PodcastEvent: Model {
  public static let schemaName = "podcasts"
  public static let tableName = "events"
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .kind: .string(self.kind.rawValue)
    case .label: .string(self.label)
    case .deviceType: .string(self.deviceType)
    case .appVersion: .string(self.appVersion)
    case .iosVersion: .string(self.iosVersion)
    case .installId: .uuid(self.installId)
    case .detail: .string(self.detail)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(self.eventId),
      .kind: .string(self.kind.rawValue),
      .label: .string(self.label),
      .deviceType: .string(self.deviceType),
      .appVersion: .string(self.appVersion),
      .iosVersion: .string(self.iosVersion),
      .installId: .uuid(self.installId),
      .detail: .string(self.detail),
      .createdAt: .currentTimestamp,
    ]
  }
}
