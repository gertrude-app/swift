import MacAppRoute
import Models

extension User {
  init(fromPairQL output: ConnectUser.Output) {
    self.init(
      id: User.Id(output.id),
      token: User.Token(output.token),
      deviceId: User.DeviceId(output.deviceId),
      name: output.name,
      keyloggingEnabled: output.keyloggingEnabled,
      screenshotsEnabled: output.screenshotsEnabled,
      screenshotFrequency: output.screenshotFrequency,
      screenshotSize: output.screenshotSize
    )
  }
}
