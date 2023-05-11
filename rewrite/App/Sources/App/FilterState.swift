import Dependencies

enum FilterState: Equatable, Codable {
  case off
  case on
  case suspended(resuming: String)
}

extension FilterState {
  init(_ rootState: AppReducer.State) {
    switch rootState.filter.extension {
    case .unknown,
         .errorLoadingConfig,
         .notInstalled,
         .installedButNotRunning:
      self = .off
    case .installedAndRunning:
      @Dependency(\.date.now) var now
      guard let expiration = rootState.filter.currentSuspensionExpiration,
            expiration > now else {
        self = .on
        return
      }
      self = .suspended(resuming: now.timeRemaining(until: expiration) ?? "now")
    }
  }
}
