import DuetSQL
import MacAppRoute
import Vapor

extension ConnectApp: Resolver {
  static func resolve(
    with input: Input,
    in context: MacAppContext
  ) async throws -> Output {
    guard let userId = await Current.ephemeral.getPendingAppConnection(input.verificationCode)
    else {
      throw Abort(.notFound, reason: "verification code not found")
    }

    let device: Device
    let user = try await Current.db.find(userId)

    // there should only ever be a single gertrude user
    // per computer + macOS user (represented by os user numeric id)
    let existing = try? await Current.db.query(Device.self)
      .where(.serialNumber == input.serialNumber)
      .where(.numericId == .int(input.numericId))
      .first()

    if let existing = existing {

      // we get in here if the gertrude app was already installed for this macOS user
      // at some point in the past, so we will update the device to be attached to this
      // user, after double-checking below that the user belongs to the same admin acct

      // sanity check - we only "transfer" a device, if the admin accounts match
      let existingUser = try await Current.db.find(existing.userId)
      if existingUser.adminId != user.adminId {
        throw Abort(.forbidden, reason: "Device already registered to another admin's user")
      }

      let oldUserId = existing.userId
      existing.hostname = input.hostname
      existing.username = input.username
      existing.fullUsername = input.fullUsername
      existing.numericId = input.numericId
      existing.serialNumber = input.serialNumber
      existing.userId = user.id

      // update the device to be attached to the user issuing this request
      device = try await Current.db.update(existing)

      try await Current.db.query(UserToken.self)
        .where(.deviceId == device.id)
        .where(.userId == oldUserId)
        .delete()

    } else {
      // create a brand new device for this user
      device = try await Current.db.create(Device(
        userId: user.id,
        appVersion: input.appVersion,
        hostname: input.hostname,
        modelIdentifier: input.modelIdentifier,
        username: input.username,
        fullUsername: input.fullUsername,
        numericId: input.numericId,
        serialNumber: input.serialNumber
      ))
    }

    let token = try await Current.db.create(UserToken(userId: user.id, deviceId: device.id))

    return Output(
      userId: user.id.rawValue,
      userName: user.name,
      token: token.value.rawValue,
      deviceId: device.id.rawValue
    )
  }
}
