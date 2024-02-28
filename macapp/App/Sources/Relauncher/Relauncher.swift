import Foundation
import os.log

public enum Relauncher {
  public static func run(_ client: RelauncherClient = .liveValue) {
    let originalParentProcessId = client.parentProcessId()
    os_log(
      "[G• relaunch] invoked pid/ppid: %{public}d / %{public}d",
      client.processId(), originalParentProcessId
    )

    let args = client.commandLineArgs()
    if args.count != 3 {
      os_log("[G• relaunch] ERR unexepected incorrect usage")
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    guard let appUrl = URL(string: args[1]) else {
      os_log("[G• relaunch] ERR invalid URL string: %{public}s", args[1])
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    guard client.fileExistsAtPath(appUrl.path) else {
      os_log("[G• relaunch] ERR app url 404: %{public}s", appUrl.absoluteString)
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    let subcommand = args[2]
    if subcommand == "--precheck" {
      os_log("[G• relaunch] test success")
      client.writeToStdout("OK")
      client.exit(0)
      return
    }

    let maxIterations: UInt64
    let sleepInterval: Double
    if subcommand == "--relaunch" {
      maxIterations = 100
      sleepInterval = 0.2
    } else if subcommand == "--crash-watch" {
      #if DEBUG
        maxIterations = 500 // prevent runaway poorly-written tests
      #else
        maxIterations = UInt64.max
      #endif
      sleepInterval = 5.0
    } else {
      os_log("[G• relaunch] ERR unknown subcommand: %{public}s", subcommand)
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    var iterations: UInt64 = 0
    os_log("[G• relaunch] start watching for program termination...")

    while true {
      iterations += 1
      client.sleepForSeconds(sleepInterval)
      os_log("[G• relaunch] continue watching for program termination...")

      // new ppid means process was orphaned because app terminated
      let currentParentProcessId = client.parentProcessId()
      if currentParentProcessId != originalParentProcessId {
        os_log(
          "[G• relaunch] termination/crash detected, relaunching, new ppid: %{public}d",
          currentParentProcessId
        )
        client.openApplication(appUrl)
        client.sleepForSeconds(0.2)
        os_log("[G• relaunch] relaunch complete, terminating helper process")
        client.exit(0)
        return
      }

      if iterations >= maxIterations {
        os_log("[G• relaunch] ERR program never terminated")
        client.writeToStdout("FAIL")
        client.exit(1)
        return
      }
    }
  }
}
