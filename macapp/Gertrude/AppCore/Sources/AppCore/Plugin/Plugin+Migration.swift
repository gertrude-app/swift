import Foundation
import Gertie
import SharedCore

class MigrationPlugin: Plugin {
  var store: AppStore

  init(store: AppStore) {
    self.store = store
  }

  func respond(to event: AppEvent) {
    switch event {
    default:
      break
    }
  }
}
