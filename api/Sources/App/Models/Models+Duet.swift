import DuetSQL
import Tagged

extension Admin: Duet.Identifiable {
  public typealias Id = Tagged<Admin, UUID>
}

public extension Admin {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case email
    case password
    case subscriptionId
    case subscriptionStatus
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension Admin.SubscriptionStatus: PostgresEnum {
  public var typeName: String { "admin_user_subscription_status" }
}

// extension AdminNotification: Duet.Identifiable {
//   public typealias Id = Tagged<AdminNotification, UUID>
// }

// public extension AdminNotification {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case adminId
//     case methodId
//     case trigger
//     case createdAt
//   }
// }

// extension AdminToken: Duet.Identifiable {
//   public typealias Id = Tagged<AdminToken, UUID>
// }

// public extension AdminToken {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case adminId
//     case value
//     case createdAt
//     case deletedAt
//   }
// }

// extension AdminVerifiedNotificationMethod: Duet.Identifiable {
//   public typealias Id = Tagged<AdminVerifiedNotificationMethod, UUID>
// }

// public extension AdminVerifiedNotificationMethod {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case adminId
//     case method
//     case createdAt
//   }
// }

// extension AppCategory: Duet.Identifiable {
//   public typealias Id = Tagged<AppCategory, UUID>
// }

// public extension AppCategory {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case name
//     case slug
//     case description
//     case createdAt
//     case updatedAt
//   }
// }

// extension BundleId: Duet.Identifiable {
//   public typealias Id = Tagged<BundleId, UUID>
// }

// public extension BundleId {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case bundleId
//     case identifiedAppId
//     case createdAt
//     case updatedAt
//   }
// }

// extension Device: Duet.Identifiable {
//   public typealias Id = Tagged<Device, UUID>
// }

// public extension Device {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case userId
//     case appVersion
//     case customName
//     case hostname
//     case modelIdentifier
//     case username
//     case fullUsername
//     case numericId
//     case serialNumber
//     case createdAt
//     case updatedAt
//   }
// }

// extension IdentifiedApp: Duet.Identifiable {
//   public typealias Id = Tagged<IdentifiedApp, UUID>
// }

// public extension IdentifiedApp {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case categoryId
//     case name
//     case slug
//     case selectable
//     case description
//     case createdAt
//     case updatedAt
//   }
// }

// extension Keychain: Duet.Identifiable {
//   public typealias Id = Tagged<Keychain, UUID>
// }

// public extension Keychain {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case authorId
//     case name
//     case description
//     case isPublic
//     case createdAt
//     case updatedAt
//     case deletedAt
//   }
// }

// extension KeyRecord: Duet.Identifiable {
//   public typealias Id = Tagged<KeyRecord, UUID>
// }

// public extension KeyRecord {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case keychainId
//     case key
//     case comment
//     case createdAt
//     case updatedAt
//     case deletedAt
//   }
// }

// extension KeystrokeLine: Duet.Identifiable {
//   public typealias Id = Tagged<KeystrokeLine, UUID>
// }

// public extension KeystrokeLine {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case deviceId
//     case appName
//     case line
//     case createdAt
//     case deletedAt
//   }
// }

// extension NetworkDecision: Duet.Identifiable {
//   public typealias Id = Tagged<NetworkDecision, UUID>
// }

// public extension NetworkDecision {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case deviceId
//     case responsibleKeyId
//     case verdict
//     case reason
//     case ipProtocolNumber
//     case hostname
//     case ipAddress
//     case url
//     case appBundleId
//     case count
//     case createdAt
//     case appDescriptor
//   }
// }

// extension Release: Duet.Identifiable {
//   public typealias Id = Tagged<Release, UUID>
// }

// public extension Release {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case semver
//     case channel
//     case signature
//     case length
//     case appRevision
//     case coreRevision
//     case createdAt
//     case updatedAt
//   }
// }

// extension Screenshot: Duet.Identifiable {
//   public typealias Id = Tagged<Screenshot, UUID>
// }

// public extension Screenshot {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case deviceId
//     case url
//     case width
//     case height
//     case createdAt
//     case deletedAt
//   }
// }

// extension SuspendFilterRequest: Duet.Identifiable {
//   public typealias Id = Tagged<SuspendFilterRequest, UUID>
// }

// public extension SuspendFilterRequest {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case deviceId
//     case status
//     case scope
//     case duration
//     case requestComment
//     case responseComment
//     case createdAt
//     case updatedAt
//   }
// }

// extension UnlockRequest: Duet.Identifiable {
//   public typealias Id = Tagged<UnlockRequest, UUID>
// }

// public extension UnlockRequest {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case networkDecisionId
//     case deviceId
//     case status
//     case requestComment
//     case responseComment
//     case createdAt
//     case updatedAt
//   }
// }

// extension User: Duet.Identifiable {
//   public typealias Id = Tagged<User, UUID>
// }

// public extension User {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case adminId
//     case name
//     case keyloggingEnabled
//     case screenshotsEnabled
//     case screenshotsResolution
//     case screenshotsFrequency
//     case createdAt
//     case updatedAt
//     case deletedAt
//   }
// }

// extension UserKeychain: Duet.Identifiable {
//   public typealias Id = Tagged<UserKeychain, UUID>
// }

// public extension UserKeychain {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case userId
//     case keychainId
//     case createdAt
//   }
// }

// extension UserToken: Duet.Identifiable {
//   public typealias Id = Tagged<UserToken, UUID>
// }

// public extension UserToken {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case userId
//     case deviceId
//     case value
//     case createdAt
//     case updatedAt
//     case deletedAt
//   }
// }

// extension WaitlistedUser: Duet.Identifiable {
//   public typealias Id = Tagged<WaitlistedUser, UUID>
// }

// public extension WaitlistedUser {
//   enum CodingKeys: String, CodingKey, CaseIterable {
//     case id
//     case email
//     case signupToken
//     case createdAt
//     case updatedAt
//   }
// }
