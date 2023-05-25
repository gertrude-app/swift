import Foundation
import Gertie
import SharedCore

extension Log.Message {
  static func mock() -> Log.Message {
    var msgs = [
      Log.Message(message: "App registered with filter extension XPC service"),
      Log.Message(
        level: .debug,
        message: "[NEW] BLOCK request to `127.0.0.1` UDP because it was a NON-DNS UDP request from app \"Docker\" (app:docker, category:programming com.docker.docker) user: 501",
        meta: ["filter_decision.verdict": "block"]
      ),
      Log.Message(
        level: .debug,
        message: "[NEW] ALLOW request to `safesite.com` because it was a permitted by keychain \"Willow\" (app:docker, category:programming com.docker.docker) user: 501",
        meta: ["filter_decision.verdict": "allow"]
      ),
      Log.Message(
        level: .error,
        message: "Failed to get downsampled jpeg data for screenshot"
      ),
      Log.Message(
        level: .error,
        message: "Failed to get downsampled jpeg data for screenshot"
      ),
    ]
    msgs.shuffle()
    return msgs[0]
  }
}

func make<T>(_ num: Int, _ f: () -> T) -> [T] {
  var xs: [T] = []
  for _ in 0 ... num {
    xs.append(f())
  }
  return xs
}
