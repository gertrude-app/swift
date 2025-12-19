import Foundation

struct IOSEvent: Codable, Sendable {
  var id: Id
  var eventId: String
  var kind: Kind
  var detail: String?
  var vendorId: UUID?
  var deviceType: String
  var iosVersion: String
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    kind: Kind,
    detail: String? = nil,
    vendorId: UUID? = nil,
    deviceType: String,
    iosVersion: String,
  ) {
    self.id = id
    self.eventId = eventId
    self.kind = kind
    self.detail = detail
    self.vendorId = vendorId
    self.deviceType = deviceType
    self.iosVersion = iosVersion
  }
}

extension IOSEvent {
  enum Kind: String, Sendable, Codable {
    case info
    case onboarding
    case filter
    case error
  }
}
