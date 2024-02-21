import AppKit
import Darwin
import Foundation
import os.log

let ppid = getppid()
os_log("[G• relaunch] invoked pid/ppid: %{public}d / %{public}d", getpid(), ppid)

if CommandLine.arguments.count != 3 {
  os_log("[G• relaunch] ERR unexepected incorrect usage")
  fputs("FAIL", stdout)
  exit(1)
}

let appUrlString = CommandLine.arguments[1]
guard let appUrl = URL(string: appUrlString) else {
  os_log("[G• relaunch] ERR invalid URL string: %{public}s", appUrlString)
  fputs("FAIL", stdout)
  exit(1)
}

guard FileManager.default.fileExists(atPath: appUrl.path) else {
  os_log("[G• relaunch] ERR app url 404: %{public}s", appUrl.absoluteString)
  fputs("FAIL", stdout)
  exit(1)
}

if CommandLine.arguments[2] == "--test" {
  os_log("[G• relaunch] test success")
  fputs("OK", stdout)
  exit(0)
}

var iterations = 0
os_log("[G• relaunch] start watching for program termination...")

while true {
  iterations += 1
  Thread.sleep(forTimeInterval: 0.2)
  os_log("[G• relaunch] continue watching for program termination...")

  // new ppid means process was orphaned because app terminated
  if getppid() != ppid {
    os_log("[G• relaunch] termination detected, relaunching, new ppid: %{public}d", getppid())
    NSWorkspace.shared.openApplication(
      at: appUrl,
      configuration: NSWorkspace.OpenConfiguration()
    )
    Thread.sleep(forTimeInterval: 0.2)
    os_log("[G• relaunch] relaunch complete, terminating helper process")
    exit(0)
  }

  if iterations > 100 {
    os_log("[G• relaunch] ERR program never terminated")
    fputs("FAIL", stdout)
    exit(1)
  }
}
