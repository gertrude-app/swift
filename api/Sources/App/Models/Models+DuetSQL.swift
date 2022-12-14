import DuetSQL
import Shared

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
      .email: .string(email.rawValue),
      .password: .string(password),
      .subscriptionId: .string(subscriptionId?.rawValue),
      .subscriptionStatus: .enum(subscriptionStatus),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

// extension AdminNotification: Model {
//   public static let tableName = M38.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .adminId:
//       return .uuid(adminId)
//     case .methodId:
//       return .uuid(methodId)
//     case .trigger:
//       return .enum(trigger)
//     case .createdAt:
//       return .date(createdAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .adminId: .uuid(adminId),
//       .methodId: .uuid(methodId),
//       .trigger: .enum(trigger),
//       .createdAt: .currentTimestamp,
//     ]
//   }
// }

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

// extension AdminVerifiedNotificationMethod: Model {
//   public static let tableName = M38.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .adminId:
//       return .uuid(adminId)
//     case .method:
//       return .json(method.toPostgresJson)
//     case .createdAt:
//       return .date(createdAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .adminId: .uuid(adminId),
//       .method: .json(method.toPostgresJson),
//       .createdAt: .currentTimestamp,
//     ]
//   }
// }

// extension AppCategory: Model {
//   public static let tableName = M7.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .name:
//       return .string(name)
//     case .slug:
//       return .string(slug)
//     case .description:
//       return .string(description)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .name: .string(name),
//       .slug: .string(slug),
//       .description: .string(description),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }

// extension BundleId: Model {
//   public static let tableName = M9.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .bundleId:
//       return .string(bundleId)
//     case .identifiedAppId:
//       return .uuid(identifiedAppId)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .bundleId: .string(bundleId),
//       .identifiedAppId: .uuid(identifiedAppId),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }

extension Device: Model {
  public static let tableName = M3.tableName
  public typealias ColumnName = CodingKeys

  public func postgresData(for column: ColumnName) -> Postgres.Data {
    switch column {
    case .id:
      return .id(self)
    case .userId:
      return .uuid(userId)
    case .appVersion:
      return .string(appVersion)
    case .customName:
      return .string(customName)
    case .hostname:
      return .string(hostname)
    case .modelIdentifier:
      return .string(modelIdentifier)
    case .username:
      return .string(username)
    case .fullUsername:
      return .string(fullUsername)
    case .numericId:
      return .int(numericId)
    case .serialNumber:
      return .string(serialNumber)
    case .createdAt:
      return .date(createdAt)
    case .updatedAt:
      return .date(updatedAt)
    }
  }

  public var insertValues: [ColumnName: Postgres.Data] {
    [
      .id: .id(self),
      .userId: .uuid(userId),
      .appVersion: .string(appVersion),
      .customName: .string(customName),
      .hostname: .string(hostname),
      .modelIdentifier: .string(modelIdentifier),
      .username: .string(username),
      .fullUsername: .string(fullUsername),
      .numericId: .int(numericId),
      .serialNumber: .string(serialNumber),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

// extension IdentifiedApp: Model {
//   public static let tableName = M8.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .categoryId:
//       return .uuid(categoryId)
//     case .name:
//       return .string(name)
//     case .slug:
//       return .string(slug)
//     case .selectable:
//       return .bool(selectable)
//     case .description:
//       return .string(description)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .categoryId: .uuid(categoryId),
//       .name: .string(name),
//       .slug: .string(slug),
//       .selectable: .bool(selectable),
//       .description: .string(description),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }

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

extension Shared.Key: PostgresJsonable {}

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

// extension KeystrokeLine: Model {
//   public static let tableName = M13.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .deviceId:
//       return .uuid(deviceId)
//     case .appName:
//       return .string(appName)
//     case .line:
//       return .string(line)
//     case .createdAt:
//       return .date(createdAt)
//     case .deletedAt:
//       return .date(deletedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .deviceId: .uuid(deviceId),
//       .appName: .string(appName),
//       .line: .string(line),
//       .createdAt: .date(createdAt),
//     ]
//   }
// }

// extension NetworkDecision: Model {
//   public static let tableName = M15.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .deviceId:
//       return .uuid(deviceId)
//     case .responsibleKeyId:
//       return .uuid(responsibleKeyId)
//     case .verdict:
//       return .enum(verdict)
//     case .reason:
//       return .enum(reason)
//     case .ipProtocolNumber:
//       return .int(ipProtocolNumber)
//     case .hostname:
//       return .string(hostname)
//     case .ipAddress:
//       return .string(ipAddress)
//     case .url:
//       return .string(url)
//     case .appBundleId:
//       return .string(appBundleId)
//     case .count:
//       return .int(count)
//     case .createdAt:
//       return .date(createdAt)
//     case .appDescriptor:
//       Current.logger
//         .error("unexpected postgresData access of sideLoadable NetworkDecision.appDescriptor")
//       return .null
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .deviceId: .uuid(deviceId),
//       .responsibleKeyId: .uuid(responsibleKeyId),
//       .verdict: .enum(verdict),
//       .reason: .enum(reason),
//       .ipProtocolNumber: .int(ipProtocolNumber),
//       .hostname: .string(hostname),
//       .ipAddress: .string(ipAddress),
//       .url: .string(url),
//       .appBundleId: .string(appBundleId),
//       .count: .int(count),
//       .createdAt: .date(createdAt),
//     ]
//   }
// }

// extension Release: Model {
//   public static let tableName = M35.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .semver:
//       return .string(semver)
//     case .channel:
//       return .enum(channel)
//     case .signature:
//       return .string(signature)
//     case .length:
//       return .int(length)
//     case .appRevision:
//       return .string(appRevision.rawValue)
//     case .coreRevision:
//       return .string(coreRevision.rawValue)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .semver: .string(semver),
//       .channel: .enum(channel),
//       .signature: .string(signature),
//       .length: .int(length),
//       .appRevision: .string(appRevision.rawValue),
//       .coreRevision: .string(coreRevision.rawValue),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }

// extension Screenshot: Model {
//   public static let tableName = M14.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .deviceId:
//       return .uuid(deviceId)
//     case .url:
//       return .string(url)
//     case .width:
//       return .int(width)
//     case .height:
//       return .int(height)
//     case .createdAt:
//       return .date(createdAt)
//     case .deletedAt:
//       return .date(deletedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .deviceId: .uuid(deviceId),
//       .url: .string(url),
//       .width: .int(width),
//       .height: .int(height),
//       .createdAt: .currentTimestamp,
//     ]
//   }
// }

// extension SuspendFilterRequest: Model {
//   public static let tableName = M18.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .deviceId:
//       return .uuid(deviceId)
//     case .status:
//       return .enum(status)
//     case .scope:
//       return .json(scope.toPostgresJson)
//     case .duration:
//       return .int(duration.rawValue)
//     case .requestComment:
//       return .string(requestComment)
//     case .responseComment:
//       return .string(responseComment)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .deviceId: .uuid(deviceId),
//       .status: .enum(status),
//       .scope: .json(scope.toPostgresJson),
//       .duration: .int(duration.rawValue),
//       .requestComment: .string(requestComment),
//       .responseComment: .string(responseComment),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }

// extension UnlockRequest: Model {
//   public static let tableName = M16.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .networkDecisionId:
//       return .uuid(networkDecisionId)
//     case .deviceId:
//       return .uuid(deviceId)
//     case .status:
//       return .enum(status)
//     case .requestComment:
//       return .string(requestComment)
//     case .responseComment:
//       return .string(responseComment)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .networkDecisionId: .uuid(networkDecisionId),
//       .deviceId: .uuid(deviceId),
//       .status: .enum(status),
//       .requestComment: .string(requestComment),
//       .responseComment: .string(responseComment),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }

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
    case .deviceId:
      return .uuid(deviceId)
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
      .deviceId: .uuid(deviceId),
      .value: .uuid(value),
      .createdAt: .currentTimestamp,
      .updatedAt: .currentTimestamp,
    ]
  }
}

// extension WaitlistedUser: Model {
//   public static let tableName = M34.tableName
//   public typealias ColumnName = CodingKeys

//   public func postgresData(for column: ColumnName) -> Postgres.Data {
//     switch column {
//     case .id:
//       return .id(self)
//     case .email:
//       return .string(email.rawValue)
//     case .signupToken:
//       return .uuid(signupToken)
//     case .createdAt:
//       return .date(createdAt)
//     case .updatedAt:
//       return .date(updatedAt)
//     }
//   }

//   public var insertValues: [ColumnName: Postgres.Data] {
//     [
//       .id: .id(self),
//       .email: .string(email.rawValue),
//       .signupToken: .uuid(signupToken),
//       .createdAt: .currentTimestamp,
//       .updatedAt: .currentTimestamp,
//     ]
//   }
// }
