import DuetSQL
import Gertie

extension Admin: Model {
  public typealias ColumnName = CodingKeys
  public static let tableName = M1.tableName

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
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension AdminNotification: Model {
  public static let tableName = M1.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .adminId: .uuid(self.adminId)
    case .methodId: .uuid(self.methodId)
    case .trigger: .enum(self.trigger)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(self.adminId),
      .methodId: .uuid(self.methodId),
      .trigger: .enum(self.trigger),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AdminToken: Model {
  public static let tableName = M1.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .adminId: .uuid(self.adminId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(self.adminId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension AdminVerifiedNotificationMethod.Config: PostgresJsonable {}

extension AdminVerifiedNotificationMethod: Model {
  public static let tableName = M1.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .adminId: .uuid(self.adminId)
    case .config: .json(self.config.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(self.adminId),
      .config: .json(self.config.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AppCategory: Model {
  public static let tableName = M6.tableName
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
  public static let tableName = M6.tableName
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

extension UserDevice: Model {
  public static let tableName = M11.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .deviceId: .uuid(self.deviceId)
    case .userId: .uuid(self.userId)
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
      .userId: .uuid(self.userId),
      .deviceId: .uuid(self.deviceId),
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

extension Device: Model {
  public static let tableName = M3.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .adminId: .uuid(self.adminId)
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
      .adminId: .uuid(self.adminId),
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
  public static let tableName = M6.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .categoryId: .uuid(self.categoryId)
    case .name: .string(self.name)
    case .slug: .string(self.slug)
    case .selectable: .bool(self.selectable)
    case .description: .string(self.description)
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
      .selectable: .bool(self.selectable),
      .description: .string(self.description),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Keychain: Model {
  public static let tableName = M2.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .authorId: .uuid(self.authorId)
    case .name: .string(self.name)
    case .description: .string(self.description)
    case .isPublic: .bool(self.isPublic)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .authorId: .uuid(self.authorId),
      .name: .string(self.name),
      .description: .string(self.description),
      .isPublic: .bool(self.isPublic),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension Gertie.Key: PostgresJsonable {}

extension Key: Model {
  public static let tableName = M2.tableName
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
  public static let tableName = M4.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .userDeviceId: .uuid(self.userDeviceId)
    case .appName: .string(self.appName)
    case .line: .string(self.line)
    case .filterSuspended: .bool(self.filterSuspended)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userDeviceId: .uuid(self.userDeviceId),
      .appName: .string(self.appName),
      .line: .string(self.line),
      .filterSuspended: .bool(self.filterSuspended),
      .createdAt: .date(self.createdAt),
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension Release: Model {
  public static let tableName = M7.tableName
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
  public static let tableName = M4.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .userDeviceId: .uuid(self.userDeviceId)
    case .url: .string(self.url)
    case .width: .int(self.width)
    case .height: .int(self.height)
    case .filterSuspended: .bool(self.filterSuspended)
    case .createdAt: .date(self.createdAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userDeviceId: .uuid(self.userDeviceId),
      .url: .string(self.url),
      .width: .int(self.width),
      .height: .int(self.height),
      .filterSuspended: .bool(self.filterSuspended),
      .createdAt: .date(self.createdAt),
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension AppScope: PostgresJsonable {}

extension SuspendFilterRequest: Model {
  public static let tableName = M5.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .userDeviceId: .uuid(self.userDeviceId)
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
      .userDeviceId: .uuid(self.userDeviceId),
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
  public static let tableName = M5.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .userDeviceId: .uuid(self.userDeviceId)
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
      .userDeviceId: .uuid(self.userDeviceId),
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

extension User: Model {
  public static let tableName = M3.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .adminId: .uuid(self.adminId)
    case .name: .string(self.name)
    case .keyloggingEnabled: .bool(self.keyloggingEnabled)
    case .screenshotsEnabled: .bool(self.screenshotsEnabled)
    case .screenshotsResolution: .int(self.screenshotsResolution)
    case .screenshotsFrequency: .int(self.screenshotsFrequency)
    case .showSuspensionActivity: .bool(self.showSuspensionActivity)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(self.adminId),
      .name: .string(self.name),
      .keyloggingEnabled: .bool(self.keyloggingEnabled),
      .screenshotsEnabled: .bool(self.screenshotsEnabled),
      .screenshotsResolution: .int(self.screenshotsResolution),
      .screenshotsFrequency: .int(self.screenshotsFrequency),
      .showSuspensionActivity: .bool(self.showSuspensionActivity),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension UserKeychain: Model {
  public static let tableName = M3.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .userId: .uuid(self.userId)
    case .keychainId: .uuid(self.keychainId)
    case .schedule: .json(self.schedule?.toPostgresJson)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userId: .uuid(self.userId),
      .keychainId: .uuid(self.keychainId),
      .schedule: .json(self.schedule?.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension KeychainSchedule: PostgresJsonable {}

extension UserToken: Model {
  public static let tableName = M3.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .userId: .uuid(self.userId)
    case .userDeviceId: .uuid(self.userDeviceId)
    case .value: .uuid(self.value)
    case .createdAt: .date(self.createdAt)
    case .updatedAt: .date(self.updatedAt)
    case .deletedAt: .date(self.deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userId: .uuid(self.userId),
      .userDeviceId: .uuid(self.userDeviceId),
      .value: .uuid(self.value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
      .deletedAt: .date(self.deletedAt),
    ]
  }
}

extension InterestingEvent: Model {
  public static let tableName = InterestingEvent.M8.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .eventId: .string(self.eventId)
    case .kind: .string(self.kind)
    case .context: .string(self.context)
    case .userDeviceId: .uuid(self.userDeviceId)
    case .adminId: .uuid(self.adminId)
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
      .userDeviceId: .uuid(self.userDeviceId),
      .adminId: .uuid(self.adminId),
      .detail: .string(self.detail),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension StripeEvent: Model {
  public static let tableName = StripeEvent.M7.tableName
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
  public static let tableName = DeletedEntity.M16.tableName
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
  public static let tableName = Browser.M20.tableName
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
  public static let tableName = UnidentifiedApp.M28.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .bundleId: .string(self.bundleId)
    case .count: .int(self.count)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(self.bundleId),
      .count: .int(self.count),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension BrowserMatch: PostgresJsonable {}

extension SecurityEvent: Model {
  public static let tableName = SecurityEvent.M21.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id: .id(self)
    case .adminId: .uuid(self.adminId)
    case .userDeviceId: .uuid(self.userDeviceId)
    case .event: .string(self.event)
    case .detail: .string(self.detail)
    case .ipAddress: .string(self.ipAddress)
    case .createdAt: .date(self.createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(self.adminId),
      .userDeviceId: .uuid(self.userDeviceId),
      .event: .string(self.event),
      .detail: .string(self.detail),
      .ipAddress: .string(self.ipAddress),
      .createdAt: .currentTimestamp,
    ]
  }
}
