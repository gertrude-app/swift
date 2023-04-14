import ComposableArchitecture
import Dependencies
import Foundation
import Models
import TestSupport
import XExpect

@testable import App

func spyOnNotifications(_ store: TestStoreOf<AppReducer>) -> ActorIsolated<[TestNotification]> {
  let spy = ActorIsolated<[TestNotification]>([])
  store.deps.device.showNotification = { title, body in
    var value = await spy.value
    value.append(TestNotification(title, body))
    let replace = value
    await spy.setValue(replace)
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
