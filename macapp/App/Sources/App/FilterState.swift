import Dependencies
import Foundation
import Gertie

extension FilterState.WithRelativeTimes: Codable {}

extension FilterState.WithTimes {
  init(from state: AppReducer.State) {
    guard case .installedAndRunning = state.filter.extension else {
      self = .off
      return
    }

    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    if let downtime = state.user.data?.downtime, downtime.contains(now, in: calendar) {
      if let pauseExpiration = state.user.downtimePausedUntil,
         pauseExpiration > now {
        self = .init(
          checkingFilterSuspensionIn: state,
          orElse: .downtimePaused(resuming: pauseExpiration)
        )
      } else {
        let plainNow = PlainTime.from(now, in: calendar)
        let downtimeEnd = now.advanced(by: .minutes(plainNow.minutesUntil(downtime.end)))
        self = .downtime(ending: downtimeEnd)
      }
      return
    }

    self = .init(checkingFilterSuspensionIn: state, orElse: .on)
  }

  private init(
    checkingFilterSuspensionIn state: AppReducer.State,
    orElse fallback: FilterState.WithTimes = .on
  ) {
    @Dependency(\.date.now) var now
    guard let suspensionExpiration = state.filter.currentSuspensionExpiration,
          suspensionExpiration > now else {
      self = fallback
      return
    }
    self = .suspended(resuming: suspensionExpiration)
  }
}

extension FilterState.WithRelativeTimes {
  init(from state: AppReducer.State) {
    @Dependency(\.date.now) var now
    self = FilterState.WithTimes(from: state).withRelativeTimes(from: now)
  }
}
