enum NotificationMethod: Codable, Equatable {
  case slack(channelId: String, channelName: String, token: String)
  case email(email: String)
  case text(phoneNumber: String)
}
