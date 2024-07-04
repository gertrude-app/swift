import ClientInterfaces
import ComposableArchitecture
import Foundation
import Gertie

public extension ApiClient {
  func securityEvent(_ event: SecurityEvent.MacApp, _ detail: String? = nil) async {
    @Dependency(\.storage) var storage
    guard let deviceId = try? await storage.loadPersistentState()?.user?.deviceId else {
      return
    }
    await self.securityEvent(deviceId: deviceId, event: event, detail: detail)
  }

  func securityEvent(deviceId: UUID, event: SecurityEvent.MacApp, detail: String? = nil) async {
    @Dependency(\.network) var network
    guard network.isConnected() else {
      buffer(event, detail, deviceId, try? await self.getUserToken())
      return
    }
    await self.logSecurityEvent(
      .init(deviceId: deviceId, event: event.rawValue, detail: detail),
      nil
    )
  }
}

struct BufferedSecurityEvent: Codable {
  let deviceId: UUID
  let userToken: UUID
  let event: SecurityEvent.MacApp
  let detail: String
}

private func buffer(
  _ event: SecurityEvent.MacApp,
  _ detail: String?,
  _ deviceId: UUID,
  _ userToken: UUID?
) {
  guard let userToken = userToken else {
    return
  }

  @Dependency(\.date.now) var now
  @Dependency(\.userDefaults) var userDefaults

  let timestampedDetail: String
  switch detail {
  case .some(let detail):
    timestampedDetail = "\(detail) (at \(now))"
  case .none:
    timestampedDetail = "at \(now)"
  }

  var buffered = (try? userDefaults.loadJson(
    at: .bufferedSecurityEventsKey,
    decoding: [BufferedSecurityEvent].self
  )) ?? []

  buffered.append(BufferedSecurityEvent(
    deviceId: deviceId,
    userToken: userToken,
    event: event,
    detail: timestampedDetail
  ))

  try? userDefaults.saveJson(
    from: buffered,
    at: .bufferedSecurityEventsKey
  )
}

extension String {
  static var bufferedSecurityEventsKey: Self { "bufferedSecurityEvents" }
}
