import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import Vapor

extension ConnectUser: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard let userId = await with(dependency: \.ephemeral)
      .getPendingAppConnection(input.verificationCode) else {
      throw context.error(
        id: "6e7fc234",
        type: .unauthorized,
        debugMessage: "verification code not found",
        userMessage: "Connection code expired, or not found. Plese create a new code and try again.",
        appTag: .connectionCodeNotFound
      )
    }

    let computerUser: ComputerUser
    let user = try await context.db.find(userId)

    var adminDevice = try? await Device.query()
      .where(.serialNumber == input.serialNumber)
      .first(in: context.db)

    // there should only ever be a single gertrude user
    // per computer + macOS user (represented by os user numeric id)
    var existingComputerUser: ComputerUser?
    if let adminDevice {
      existingComputerUser = try? await ComputerUser.query()
        .where(.computerId == adminDevice.id)
        .where(.numericId == .int(input.numericId))
        .first(in: context.db)
    }

    if var existingComputerUser {
      // we get in here if the gertrude app was already installed for this macOS user
      // at some point in the past, so we will update the ComputerUser to be attached to this
      // user, after double-checking below that the user belongs to the same admin acct

      // sanity check - we only "transfer" a device, if the admin accounts match
      let existingUser = try await existingComputerUser.child(in: context.db)
      if existingUser.parentId != user.parentId {
        throw context.error(
          id: "41a43089",
          type: .unauthorized,
          debugMessage: "invalid connect transfer attempt",
          userMessage: "This user is associated with another Gertrude parent account."
        )
      }

      let oldUserId = existingComputerUser.childId
      existingComputerUser.username = input.username
      existingComputerUser.fullUsername = input.fullUsername
      existingComputerUser.childId = user.id
      existingComputerUser.isAdmin = input.isAdmin

      // update the device to be attached to the user issuing this request
      computerUser = try await context.db.update(existingComputerUser)

      let oldTokens = try await MacAppToken.query()
        .where(.computerUserId == computerUser.id)
        .where(.childId == oldUserId)
        .all(in: context.db)

      @Dependency(\.date.now) var now
      for var token in oldTokens {
        // wait 14 days, so buffered security events can be resent
        token.deletedAt = now + .days(14)
        try await context.db.update(token)
      }

    } else {
      if adminDevice == nil {
        // create new admin device if we don't have one
        adminDevice = try await context.db.create(Device(
          parentId: user.parentId,
          osVersion: input.osVersion.flatMap(Semver.init),
          modelIdentifier: input.modelIdentifier,
          serialNumber: input.serialNumber
        ))
      }

      // ...and create the user device
      computerUser = try await context.db.create(ComputerUser(
        childId: user.id,
        computerId: adminDevice?.id ?? .init(),
        isAdmin: input.isAdmin,
        appVersion: input.appVersion,
        username: input.username,
        fullUsername: input.fullUsername,
        numericId: input.numericId
      ))
    }

    let token = try await context.db.create(MacAppToken(
      childId: user.id,
      computerUserId: computerUser.id
    ))

    await notifyAdConversion(child: user, db: context.db)

    return Output(
      id: user.id.rawValue,
      token: token.value.rawValue,
      deviceId: computerUser.id.rawValue,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotFrequency: user.screenshotsFrequency,
      screenshotSize: user.screenshotsResolution
    )
  }
}

// helpers

private func notifyAdConversion(child: Child, db: any DuetSQL.Client) async {
  guard let parent = try? await db.find(child.parentId),
        let gclid = parent.gclid else {
    return
  }

  let markerEvent = try? await InterestingEvent.query()
    .where(.eventId == "g-ad-conversion")
    .where(.parentId == parent.id)
    .first(in: db)

  if markerEvent == nil {
    with(dependency: \.postmark).toSuperAdmin(
      "google ad conversion",
      "gclid: <code>\(gclid)</code><br/>time: <code>\(Date())</code>"
    )
    _ = try? await db.create(InterestingEvent(
      eventId: "g-ad-conversion",
      kind: "event",
      context: "reporting",
      parentId: parent.id
    ))
  }
}
