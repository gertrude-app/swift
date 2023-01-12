class HoneycombPlugin: Plugin {
  private var store: AppStore

  init(store: AppStore) {
    self.store = store
  }

  func respond(to event: AppEvent) {
    switch event {
    case .allPluginsAdded:
      Current.honeycomb.addDefaultMeta([
        "app.version": .string(Current.appVersion),
        "account.user_id": .init(Current.deviceStorage.getUUID(.gertrudeUserId)?.redacted),
        "account.user_token": .init(Current.deviceStorage.getUUID(.userToken)?.redacted),
        "account.device_id": .init(Current.deviceStorage.getUUID(.gertrudeDeviceId)?.redacted),
      ])
    case .userTokenChanged:
      Current.honeycomb.addDefaultMeta([
        "account.user_id": .init(Current.deviceStorage.getUUID(.gertrudeUserId)?.redacted),
        "account.user_token": .init(Current.deviceStorage.getUUID(.userToken)?.redacted),
        "account.device_id": .init(Current.deviceStorage.getUUID(.gertrudeDeviceId)?.redacted),
      ])
    default:
      break
    }
  }
}
