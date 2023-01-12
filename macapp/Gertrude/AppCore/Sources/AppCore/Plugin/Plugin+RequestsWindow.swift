import Foundation
import SharedCore
import SwiftUI
import XCore

class RequestsWindowPlugin: NSObject, WindowPlugin {
  var store: AppStore
  var windowOpen = false
  var timer: Timer?
  var window: NSWindow?
  var title = "Requests  |  Gertrude"

  var initialDims: (width: CGFloat, height: CGFloat) {
    (width: RequestsWindow.MIN_WIDTH, height: RequestsWindow.MIN_HEIGHT)
  }

  var contentView: NSView {
    NSHostingView(rootView: RequestsWindow().environmentObject(store))
  }

  init(store: AppStore) {
    self.store = store
  }

  func respond(to event: AppEvent) {
    switch event {
    case .requestsWindowOpened:
      openWindow()
      startFetchingRecentDecisions()
    default:
      break
    }
  }

  func startFetchingRecentDecisions() {
    fetchRecentDecisions()
    timer = Timer.repeating(every: 1.0) { [weak self] _ in
      self?.fetchRecentDecisions()
    }
  }

  func fetchRecentDecisions() {
    SendToFilter.getRecentFilterDecisions { [weak self] data in
      DispatchQueue.main.async {
        let decisions = data.compactMap { try? JSON.decode($0, as: FilterDecision.self) }
        guard decisions.count > 0 else {
          return
        }
        Current.api.uploadFilterDecisions(decisions)
        self?.store.send(.requestsWindowReceiveNewDecisions(decisions))
      }
    }
  }

  func windowWillClose(_ notification: Notification) {
    windowOpen = false
    timer?.invalidate()
  }
}
