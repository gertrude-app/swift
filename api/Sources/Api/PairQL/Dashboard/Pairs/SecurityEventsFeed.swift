import DuetSQL
import Gertie
import PairQL

struct SecurityEventsFeed: Pair {
  static let auth: ClientAuth = .admin

  struct ChildSecurityEvent: PairNestable {
    var id: SecurityEvent.Id
    var childId: User.Id
    var childName: String
    var deviceId: Device.Id
    var deviceName: String
    var event: String
    var detail: String?
    var explanation: String
    var createdAt: Date
  }

  struct AdminSecurityEvent: PairNestable {
    var id: SecurityEvent.Id
    var event: String
    var detail: String?
    var explanation: String
    var ipAddress: String?
    var createdAt: Date
  }

  enum FeedEvent: PairOutput {
    case child(ChildSecurityEvent)
    case admin(AdminSecurityEvent)
  }

  typealias Output = [FeedEvent]
}

// resolver

extension SecurityEventsFeed: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let models = try await SecurityEvent.query()
      .where(.adminId == context.admin.id)
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .all()

    let children = try await context.admin.users()
      .reduce(into: [User.Id: User]()) { result, user in
        result[user.id] = user
      }

    let devices = try await context.admin.devices()
    let userDevices = try await UserDevice.query()
      .where(.deviceId |=| devices.map(\.id))
      .all()
      .reduce(into: [UserDevice.Id: UserDevice]()) { result, userDevice in
        result[userDevice.id] = userDevice
      }

    return models.compactMap { model in
      if let userDeviceId = model.userDeviceId {
        guard let userDevice = userDevices[userDeviceId],
              let child = children[userDevice.userId],
              let device = devices.first(where: { $0.id == userDevice.deviceId }),
              let event = Gertie.SecurityEvent.MacApp(rawValue: model.event) else {
          return nil
        }
        return .child(.init(
          id: model.id,
          childId: child.id,
          childName: child.name,
          deviceId: userDevice.deviceId,
          deviceName: device.customName ?? device.model.shortDescription,
          event: event.toWords,
          detail: model.detail,
          explanation: event.explanation,
          createdAt: model.createdAt
        ))
      } else {
        guard let event = Gertie.SecurityEvent.Dashboard(rawValue: model.event) else {
          return nil
        }
        return .admin(.init(
          id: model.id,
          event: event.toWords,
          detail: model.detail,
          explanation: event.explanation,
          ipAddress: model.ipAddress,
          createdAt: model.createdAt
        ))
      }
    }
  }
}
