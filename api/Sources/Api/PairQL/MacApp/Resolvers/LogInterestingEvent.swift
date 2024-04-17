import DuetSQL
import MacAppRoute

extension LogInterestingEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    Task {
      // prevent FK error if device id deleted, or invalid
      let userDeviceId: UserDevice.Id?
      if let deviceIdInput = input.deviceId,
         let device = try? await Current.db.find(UserDevice.Id(deviceIdInput)) {
        userDeviceId = device.id
      } else {
        userDeviceId = nil
      }

      try await InterestingEvent.create(.init(
        eventId: input.eventId,
        kind: input.kind,
        context: "macapp",
        userDeviceId: userDeviceId,
        adminId: nil,
        detail: input.detail
      ))

      let detail = input.detail.map { ", detail: _\($0)_" } ?? ""
      let codeSearchLink = Slack.link(
        to: "https://github.com/search?q=repo%3Agertrude-app%2Fswift%20\(input.eventId)&type=code",
        withText: input.eventId
      )

      if input.kind == "unexpected error" {
        await Current.slack.sysLog("Unexpected macapp error: \(codeSearchLink)\(detail)")
      } else {
        await Current.slack.sysLog("Macapp interesting event: \(codeSearchLink)\(detail)")
      }
    }

    return .success
  }
}
