#if DEBUG

  import Foundation
  import Gertie
  import SharedCore

  struct XcodeLogger: LoggerProtocol {
    var printLocation = false
    var printMeta = true

    func log(_ logMsg: Log.Message) {
      let time = conciseTimeFormatter.string(from: logMsg.date)
      let primary = logMsg.meta["meta.primary"]
      var message = logMsg.message.truncate(ifLongerThan: 150, with: "[...]")

      if message == "reducer received action" {
        if primary!.description.contains("emitAppEvent") {
          let event = primary!.description.replacingOccurrences(of: "AppCore.AppEvent", with: "")
          message += ": .\(event)"
        } else {
          let appAction = primary!.description.split(separator: "(").first!
          message += ": .\(appAction)"
        }
      } else if message.count < 100, let desc = primary?.description, desc.count < 50 {
        message += " > meta.primary: \(desc)"
      }

      print("\(logMsg.level.emoji) \(time) • \(message)")

      if printMeta {
        for (key, value) in logMsg.meta {
          if shouldPrintMeta(key, value, message) {
            print("   \(key): \(value)")
          }
        }
        print("")
      }
    }

    private func shouldPrintMeta(_ key: String, _ value: Log.MetaValue, _ msg: String) -> Bool {
      if !printLocation, key == "location" { return false }
      if key == "json.raw", msg.contains("AppIdManifest") { return false }
      return true
    }
  }

#endif
