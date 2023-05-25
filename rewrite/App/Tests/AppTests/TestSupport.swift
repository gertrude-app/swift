import ClientInterfaces
import ComposableArchitecture
import Dependencies
import Foundation
import TestSupport
import XExpect

@testable import App

func spyOnNotifications(_ store: TestStoreOf<AppReducer>) -> ActorIsolated<[TestNotification]> {
  let spy = ActorIsolated<[TestNotification]>([])
  store.deps.device.showNotification = { title, body in
    await spy.append(TestNotification(title, body))
  }
  return spy
}

struct TestNotification: Equatable {
  var title: String
  var body: String
  init(_ title: String, _ body: String) {
    self.title = title
    self.body = body
  }
}
