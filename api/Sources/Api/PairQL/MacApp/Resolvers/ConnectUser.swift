import DuetSQL
import Gertie
import MacAppRoute
import Vapor

extension ConnectUser: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let userId = await Current.ephemeral.getPendingAppConnection(input.verificationCode)
    else { throw context.error(
      id: "6e7fc234",
      type: .unauthorized,
      debugMessage: "verification code not found",
      userMessage: "Connection code not found, or expired. Please try again.",
      appTag: .connectionCodeNotFound
    ) }

    let userDevice: UserDevice
    let user = try await User.find(userId)

    var adminDevice = try? await Device.query()
      .where(.serialNumber == input.serialNumber)
      .first()

    // there should only ever be a single gertrude user
    // per computer + macOS user (represented by os user numeric id)
    var existingUserDevice: UserDevice?
    if let adminDevice {
      existingUserDevice = try? await UserDevice.query()
        .where(.deviceId == adminDevice.id)
        .where(.numericId == .int(input.numericId))
        .first()
    }

    if let existingUserDevice {
      // we get in here if the gertrude app was already installed for this macOS user
      // at some point in the past, so we will update the UserDevice to be attached to this
      // user, after double-checking below that the user belongs to the same admin acct

      // sanity check - we only "transfer" a device, if the admin accounts match
      let existingUser = try await existingUserDevice.user()
      if existingUser.adminId != user.adminId {
        throw context.error(
          id: "41a43089",
          type: .unauthorized,
          debugMessage: "invalid connect transfer attempt",
          userMessage: "This user is associated with another Gertrude parent account."
        )
      }

      let oldUserId = existingUserDevice.userId
      existingUserDevice.username = input.username
      existingUserDevice.fullUsername = input.fullUsername
      existingUserDevice.userId = user.id
      existingUserDevice.isAdmin = input.isAdmin

      // update the device to be attached to the user issuing this request
      userDevice = try await existingUserDevice.save()

      let oldTokens = try await UserToken.query()
        .where(.userDeviceId == userDevice.id)
        .where(.userId == oldUserId)
        .all()

      for token in oldTokens {
        // wait 14 days, so buffered security events can be resent
        token.deletedAt = Current.date().advanced(by: .days(14))
        try await token.save()
      }

    } else {
      if adminDevice == nil {
        // create new admin device if we don't have one
        adminDevice = try await Device(
          adminId: user.adminId,
          osVersion: input.osVersion.flatMap(Semver.init),
          modelIdentifier: input.modelIdentifier,
          serialNumber: input.serialNumber
        ).create()
      }

      // ...and create the user device
      userDevice = try await UserDevice(
        userId: user.id,
        deviceId: adminDevice?.id ?? .init(),
        isAdmin: input.isAdmin,
        appVersion: input.appVersion,
        username: input.username,
        fullUsername: input.fullUsername,
        numericId: input.numericId
      ).create()
    }

    let token = try await UserToken(
      userId: user.id,
      userDeviceId: userDevice.id
    ).create()

    return Output(
      id: user.id.rawValue,
      token: token.value.rawValue,
      deviceId: userDevice.id.rawValue,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotFrequency: user.screenshotsFrequency,
      screenshotSize: user.screenshotsResolution
    )
  }
}
