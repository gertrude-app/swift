import Dependencies
import Gertie

extension FilterState.WithRelativeTimes: Codable {}

extension FilterState.WithRelativeTimes {
  init(from state: AppReducer.State) {
    guard case .installedAndRunning = state.filter.extension else {
      self = .off
      return
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar

    let now = date.now
    if let downtime = state.user.data?.downtime, downtime.contains(now, in: calendar) {
      if let pauseExpiration = state.user.downtimePausedUntil,
         pauseExpiration > now {
        self = .downtimePaused(resuming: now.timeRemaining(until: pauseExpiration))
      } else {
        let plainNow = PlainTime.from(now, in: calendar)
        let downtimeEnd = now.advanced(by: .minutes(plainNow.minutesUntil(downtime.end)))
        self = .downtime(ending: now.timeRemaining(until: downtimeEnd))
      }
      return
    }

    guard let suspensionExpiration = state.filter.currentSuspensionExpiration,
          suspensionExpiration > now else {
      self = .on
      return
    }
    self = .suspended(resuming: now.timeRemaining(until: suspensionExpiration))
  }
}

extension FilterState.WithoutTimes {
  init(from state: AppReducer.State) {
    self = FilterState.WithRelativeTimes(from: state).withoutTimes
  }
}
