import DuetSQL
import Gertie
import PairQL

struct QueryAdmins: Pair {
  static var auth: ClientAuth = .superAdmin

  struct AdminData: PairOutput {
    struct Child: PairNestable {
      struct Installation: PairNestable {
        let userId: Int
        let appVersion: String
        let filterVersion: String
        let modelIdentifier: String
        let appReleaseChannel: ReleaseChannel
        let createdAt: Date
      }

      let name: String
      let keyloggingEnabled: Bool
      let screenshotsEnabled: Bool
      let numKeychains: Int
      let numKeys: Int
      let numActivityItems: Int
      let installations: [Installation]
      let createdAt: Date
    }

    let id: Admin.Id
    let email: EmailAddress
    let subscriptionId: Admin.SubscriptionId?
    let subscriptionStatus: Admin.SubscriptionStatus
    let numNotifications: Int
    let numKeychains: Int
    let children: [Child]
    let createdAt: Date
  }

  typealias Output = [AdminData]
}

// resolver

extension QueryAdmins: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let admins = try await Admin.query().all()
    return try await admins.concurrentMap { admin in
      async let notifications = admin.notifications()
      async let keychains = admin.keychains()
      async let children = admin.users()
      return .init(
        id: admin.id,
        email: admin.email,
        subscriptionId: admin.subscriptionId,
        subscriptionStatus: admin.subscriptionStatus,
        numNotifications: (try await notifications).count,
        numKeychains: (try await keychains).count,
        children: try await (try await children).concurrentMap { child in
          async let keychains = child.keychains()
          async let devices = child.devices()
          var numKeys = 0
          for keychain in try await keychains {
            let keys = try await keychain.keys()
            numKeys += keys.count
          }
          let deviceIds = try await devices.map(\.id)
          async let screenshots = Screenshot.query().where(.userDeviceId |=| deviceIds).all()
          async let keystrokes = KeystrokeLine.query().where(.userDeviceId |=| deviceIds).all()
          let numActivityItems = (try await screenshots).count + (try await keystrokes).count
          return .init(
            name: child.name,
            keyloggingEnabled: child.keyloggingEnabled,
            screenshotsEnabled: child.screenshotsEnabled,
            numKeychains: (try await keychains).count,
            numKeys: numKeys,
            numActivityItems: numActivityItems,
            installations: try await (try await devices).concurrentMap { device in
              let adminDevice = try await device.adminDevice()
              return .init(
                userId: device.numericId,
                appVersion: device.appVersion,
                filterVersion: adminDevice.filterVersion?.string ?? "unknown",
                modelIdentifier: adminDevice.modelIdentifier,
                appReleaseChannel: adminDevice.appReleaseChannel,
                createdAt: device.createdAt
              )
            },
            createdAt: child.createdAt
          )
        },
        createdAt: admin.createdAt
      )
    }
  }
}
