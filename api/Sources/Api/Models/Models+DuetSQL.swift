import DuetSQL
import Gertie

extension Admin: Model {
  public static let tableName = M1.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .email:
      return .string(email.rawValue)
    case .password:
      return .string(password)
    case .subscriptionId:
      return .string(subscriptionId?.rawValue)
    case .subscriptionStatus:
      return .enum(subscriptionStatus)
    case .subscriptionStatusExpiration:
      return .date(subscriptionStatusExpiration)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
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
    case .id:
      return .id(self)
    case .adminId:
      return .uuid(adminId)
    case .methodId:
      return .uuid(methodId)
    case .trigger:
      return .enum(trigger)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(adminId),
      .methodId: .uuid(methodId),
      .trigger: .enum(trigger),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AdminToken: Model {
  public static let tableName = M1.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .adminId:
      return .uuid(adminId)
    case .value:
      return .uuid(value)
    case .createdAt:
      return .date(createdAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(adminId),
      .value: .uuid(value),
      .createdAt: .currentTimestamp,
      .deletedAt: .date(deletedAt),
    ]
  }
}

extension AdminVerifiedNotificationMethod.Config: PostgresJsonable {}

extension AdminVerifiedNotificationMethod: Model {
  public static let tableName = M1.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .adminId:
      return .uuid(adminId)
    case .config:
      return .json(config.toPostgresJson)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(adminId),
      .config: .json(config.toPostgresJson),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension AppCategory: Model {
  public static let tableName = M6.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .name:
      return .string(name)
    case .slug:
      return .string(slug)
    case .description:
      return .string(description)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .name: .string(name),
      .slug: .string(slug),
      .description: .string(description),
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
    case .id:
      return .id(self)
    case .bundleId:
      return .string(bundleId)
    case .identifiedAppId:
      return .uuid(identifiedAppId)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .bundleId: .string(bundleId),
      .identifiedAppId: .uuid(identifiedAppId),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension UserDevice: Model {
  public static let tableName = "user_devices" // TODO: device-refactor
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .deviceId:
      return .uuid(deviceId)
    case .userId:
      return .uuid(userId)
    case .appVersion:
      return .string(appVersion)
    case .fullUsername:
      return .string(fullUsername)
    case .numericId:
      return .int(numericId)
    case .username:
      return .string(username)
    case .updatedAt:
      return .date(updatedAt)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userId: .uuid(userId),
      .deviceId: .uuid(deviceId),
      .appVersion: .string(appVersion),
      .username: .string(username),
      .fullUsername: .string(fullUsername),
      .numericId: .int(numericId),
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
    case .id:
      return .id(self)
    case .adminId:
      return .uuid(adminId)
    case .customName:
      return .string(customName)
    case .modelIdentifier:
      return .string(modelIdentifier)
    case .serialNumber:
      return .string(serialNumber)
    case .appReleaseChannel:
      return .enum(appReleaseChannel)
    case .filterVersion:
      return .varchar(filterVersion?.string)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(adminId),
      .customName: .string(customName),
      .modelIdentifier: .string(modelIdentifier),
      .serialNumber: .string(serialNumber),
      .appReleaseChannel: .enum(appReleaseChannel),
      .filterVersion: .varchar(filterVersion?.string),
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
    case .id:
      return .id(self)
    case .categoryId:
      return .uuid(categoryId)
    case .name:
      return .string(name)
    case .slug:
      return .string(slug)
    case .selectable:
      return .bool(selectable)
    case .description:
      return .string(description)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .categoryId: .uuid(categoryId),
      .name: .string(name),
      .slug: .string(slug),
      .selectable: .bool(selectable),
      .description: .string(description),
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
    case .id:
      return .id(self)
    case .authorId:
      return .uuid(authorId)
    case .name:
      return .string(name)
    case .description:
      return .string(description)
    case .isPublic:
      return .bool(isPublic)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .authorId: .uuid(authorId),
      .name: .string(name),
      .description: .string(description),
      .isPublic: .bool(isPublic),
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
    case .id:
      return .id(self)
    case .keychainId:
      return .uuid(keychainId)
    case .key:
      return .json(key.toPostgresJson)
    case .comment:
      return .string(comment)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .keychainId: .uuid(keychainId),
      .key: .json(key.toPostgresJson),
      .comment: .string(comment),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension KeystrokeLine: Model {
  public static let tableName = M4.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .appName:
      return .string(appName)
    case .line:
      return .string(line)
    case .filterSuspended:
      return .bool(filterSuspended)
    case .createdAt:
      return .date(createdAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userDeviceId: .uuid(userDeviceId),
      .appName: .string(appName),
      .line: .string(line),
      .filterSuspended: .bool(filterSuspended),
      .createdAt: .date(createdAt),
    ]
  }
}

extension NetworkDecision: Model {
  public static let tableName = M5.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .responsibleKeyId:
      return .uuid(responsibleKeyId)
    case .verdict:
      return .enum(verdict)
    case .reason:
      return .enum(reason)
    case .ipProtocolNumber:
      return .int(ipProtocolNumber)
    case .hostname:
      return .string(hostname)
    case .ipAddress:
      return .string(ipAddress)
    case .url:
      return .string(url)
    case .appBundleId:
      return .string(appBundleId)
    case .count:
      return .int(count)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userDeviceId: .uuid(userDeviceId),
      .responsibleKeyId: .uuid(responsibleKeyId),
      .verdict: .enum(verdict),
      .reason: .enum(reason),
      .ipProtocolNumber: .int(ipProtocolNumber),
      .hostname: .string(hostname),
      .ipAddress: .string(ipAddress),
      .url: .string(url),
      .appBundleId: .string(appBundleId),
      .count: .int(count),
      .createdAt: .date(createdAt),
    ]
  }
}

extension Release: Model {
  public static let tableName = M7.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .semver:
      return .string(semver)
    case .channel:
      return .enum(channel)
    case .signature:
      return .string(signature)
    case .length:
      return .int(length)
    case .revision:
      return .string(revision.rawValue)
    case .requirementPace:
      return .int(requirementPace)
    case .notes:
      return .string(notes)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .semver: .string(semver),
      .channel: .enum(channel),
      .signature: .string(signature),
      .length: .int(length),
      .revision: .string(revision.rawValue),
      .requirementPace: .int(requirementPace),
      .notes: .string(notes),
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
    case .id:
      return .id(self)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .url:
      return .string(url)
    case .width:
      return .int(width)
    case .height:
      return .int(height)
    case .filterSuspended:
      return .bool(filterSuspended)
    case .createdAt:
      return .date(createdAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userDeviceId: .uuid(userDeviceId),
      .url: .string(url),
      .width: .int(width),
      .height: .int(height),
      .filterSuspended: .bool(filterSuspended),
      .createdAt: .date(createdAt),
    ]
  }
}

extension AppScope: PostgresJsonable {}

extension SuspendFilterRequest: Model {
  public static let tableName = M5.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .status:
      return .enum(status)
    case .scope:
      return .json(scope.toPostgresJson)
    case .duration:
      return .int(duration.rawValue)
    case .requestComment:
      return .string(requestComment)
    case .responseComment:
      return .string(responseComment)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userDeviceId: .uuid(userDeviceId),
      .status: .enum(status),
      .scope: .json(scope.toPostgresJson),
      .duration: .int(duration.rawValue),
      .requestComment: .string(requestComment),
      .responseComment: .string(responseComment),
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
    case .id:
      return .id(self)
    case .networkDecisionId:
      return .uuid(networkDecisionId)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .status:
      return .enum(status)
    case .requestComment:
      return .string(requestComment)
    case .responseComment:
      return .string(responseComment)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .networkDecisionId: .uuid(networkDecisionId),
      .userDeviceId: .uuid(userDeviceId),
      .status: .enum(status),
      .requestComment: .string(requestComment),
      .responseComment: .string(responseComment),
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
    case .id:
      return .id(self)
    case .adminId:
      return .uuid(adminId)
    case .name:
      return .string(name)
    case .keyloggingEnabled:
      return .bool(keyloggingEnabled)
    case .screenshotsEnabled:
      return .bool(screenshotsEnabled)
    case .screenshotsResolution:
      return .int(screenshotsResolution)
    case .screenshotsFrequency:
      return .int(screenshotsFrequency)
    case .showSuspensionActivity:
      return .bool(showSuspensionActivity)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .adminId: .uuid(adminId),
      .name: .string(name),
      .keyloggingEnabled: .bool(keyloggingEnabled),
      .screenshotsEnabled: .bool(screenshotsEnabled),
      .screenshotsResolution: .int(screenshotsResolution),
      .screenshotsFrequency: .int(screenshotsFrequency),
      .showSuspensionActivity: .bool(showSuspensionActivity),
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
    case .id:
      return .id(self)
    case .userId:
      return .uuid(userId)
    case .keychainId:
      return .uuid(keychainId)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userId: .uuid(userId),
      .keychainId: .uuid(keychainId),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension UserToken: Model {
  public static let tableName = M3.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .userId:
      return .uuid(userId)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .value:
      return .uuid(value)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    case .deletedAt:
      return .date(deletedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userId: .uuid(userId),
      .userDeviceId: .uuid(userDeviceId),
      .value: .uuid(value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

extension InterestingEvent: Model {
  public static let tableName = InterestingEvent.M8.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .eventId:
      return .string(eventId)
    case .kind:
      return .string(kind)
    case .context:
      return .string(context)
    case .userDeviceId:
      return .uuid(userDeviceId)
    case .adminId:
      return .uuid(adminId)
    case .detail:
      return .string(detail)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .eventId: .string(eventId),
      .kind: .string(kind),
      .context: .string(context),
      .userDeviceId: .uuid(userDeviceId),
      .adminId: .uuid(adminId),
      .detail: .string(detail),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension StripeEvent: Model {
  public static let tableName = StripeEvent.M7.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .json:
      return .string(json)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .json: .string(json),
      .createdAt: .currentTimestamp,
    ]
  }
}

extension DeletedEntity: Model {
  public static let tableName = DeletedEntity.M16.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .type:
      return .string(type)
    case .reason:
      return .string(reason)
    case .data:
      return .string(data)
    case .createdAt:
      return .date(createdAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .type: .string(type),
      .reason: .string(reason),
      .data: .string(data),
      .createdAt: .currentTimestamp,
    ]
  }
}
