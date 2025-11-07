import Foundation
import os.log

public enum Relauncher {
  public static func run(_ client: RelauncherClient = .liveValue) {
    let originalParentProcessId = client.parentProcessId()
    os_log(
      "[G•] HELPER invoked pid=%{public}d, ppid=%{public}d",
      client.processId(), originalParentProcessId,
    )

    let args = client.commandLineArgs()
    if args.count != 3 {
      os_log("[G•] HELPER ERR unexepected incorrect usage")
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    guard let appUrl = URL(string: args[1]) else {
      os_log("[G•] HELPER ERR invalid URL string: %{public}s", args[1])
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    guard client.fileExistsAtPath(appUrl.path) else {
      os_log("[G•] HELPER ERR app url 404: %{public}s", appUrl.absoluteString)
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    let subcommand = args[2]
    if subcommand == "--precheck" {
      os_log("[G•] HELPER test success, app url path: %{public}s", appUrl.path)
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
      os_log("[G•] HELPER ERR unknown subcommand: %{public}s", subcommand)
      client.writeToStdout("FAIL")
      client.exit(1)
      return
    }

    var iterations: UInt64 = 0
    os_log("[G•] HELPER start watching for program termination...")

    while true {
      iterations += 1
      client.sleepForSeconds(sleepInterval)
      if iterations % 20 == 0 {
        os_log("[G•] HELPER checking for program termination (1/20)...")
      } else if iterations % 5 == 0 {
        os_log("[D•] HELPER checking for program termination (1/5)...")
      }

      // new ppid means process was orphaned because app terminated
      let currentParentProcessId = client.parentProcessId()
      if currentParentProcessId != originalParentProcessId {
        os_log(
          "[G•] HELPER termination/crash likely, new ppid: %{public}d",
          currentParentProcessId,
        )

        if client.runningApplicationsBundleUrlPaths().contains(appUrl.path) {
          os_log("[G•] HELPER app relaunched by auto-update, exiting")
          client.exit(0)
          return
        }

        os_log("[G•] HELPER relaunching app")
        client.openApplication(appUrl)
        client.sleepForSeconds(0.2)
        os_log("[G•] HELPER relaunch complete, exiting")
        client.exit(0)
        return
      }

      if iterations >= maxIterations {
        os_log("[G•] HELPER ERR program never terminated")
        client.writeToStdout("FAIL")
        client.exit(1)
        return
      }
    }
  }
}
