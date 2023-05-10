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
      guard let expiration = rootState.filter.currentSuspensionExpiration else {
        self = .on
        return
      }
      @Dependency(\.date.now) var now
      self = .suspended(resuming: now.timeRemaining(until: expiration) ?? "now")
    }
  }
}
