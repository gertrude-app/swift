import ComposableArchitecture
import Core
import Gertie
import TestSupport
import XCTest
import XExpect

@testable import App

final class MenuBarFeatureTests: XCTestCase {
  @MainActor
  func testDowntimePausedAndUnpaused() async {
    let now = Calendar.current.date(from: DateComponents(hour: 23, minute: 30))!
    let pauseDowntime = spy(on: Date.self, returning: Result<Void, XPCErr>.success(()))
    let resumeDowntime = mock(once: Result<Void, XPCErr>.success(()))
    await withDependencies {
      $0.filterXpc.pauseDowntime = pauseDowntime.fn
      $0.filterXpc.endDowntimePause = resumeDowntime.fn
      $0.calendar = .init(identifier: .gregorian)
      $0.date = .constant(now)
    } operation: {
      let (store, _) = AppReducer.testStore(mockDeps: false) {
        $0.filter.extension = .installedAndRunning
        $0.user.data = .mock { $0.downtime = "22:00-05:00" }
      }

      expect(FilterState.WithRelativeTimes(from: store.state))
        .toEqual(.downtime(ending: "about 6 hours from now"))

      await store.send(.adminAuthed(.menuBar(.pauseDowntimeClicked(duration: .tenMinutes)))) {
        $0.user.downtimePausedUntil = now + .minutes(10)
      }

      expect(await pauseDowntime.calls).toEqual([now + .minutes(10)])
      expect(FilterState.WithRelativeTimes(from: store.state))
        .toEqual(.downtimePaused(resuming: "10 minutes from now"))

      await store.send(.menuBar(.resumeDowntimeClicked)) {
        $0.user.downtimePausedUntil = nil
      }

      expect(await resumeDowntime.calls.count).toEqual(1)

      expect(FilterState.WithRelativeTimes(from: store.state))
        .toEqual(.downtime(ending: "about 6 hours from now"))
    }
  }

  @MainActor
  func testPauseDowntimeClickedButNotDuringDowntime() async {
    let now = Calendar.current.date(from: DateComponents(hour: 05, minute: 30))!
    await withDependencies {
      $0.calendar = .init(identifier: .gregorian)
      $0.date = .constant(now)
      $0.filterXpc.pauseDowntime = { _ in fatalError("not called") }
    } operation: {
      let (store, _) = AppReducer.testStore(mockDeps: false) {
        $0.filter.extension = .installedAndRunning
        $0.user.data = .mock { $0.downtime = "22:00-05:00" }
      }

      expect(FilterState.WithRelativeTimes(from: store.state)).toEqual(.on)
      await store.send(.adminAuthed(.menuBar(.pauseDowntimeClicked(duration: .tenMinutes))))
      expect(FilterState.WithRelativeTimes(from: store.state)).toEqual(.on)
    }
  }

  @MainActor
  func testPauseDowntimeClickedButNoDowntime() async {
    let now = Calendar.current.date(from: DateComponents(hour: 05, minute: 30))!
    await withDependencies {
      $0.calendar = .init(identifier: .gregorian)
      $0.date = .constant(now)
      $0.filterXpc.pauseDowntime = { _ in fatalError("not called") }
    } operation: {
      let (store, _) = AppReducer.testStore(mockDeps: false) {
        $0.filter.extension = .installedAndRunning
        $0.user.data = .mock { $0.downtime = nil } // <-- no downtime!
      }

      expect(FilterState.WithRelativeTimes(from: store.state)).toEqual(.on)
      await store.send(.adminAuthed(.menuBar(.pauseDowntimeClicked(duration: .tenMinutes))))
      expect(FilterState.WithRelativeTimes(from: store.state)).toEqual(.on)
    }
  }
}
