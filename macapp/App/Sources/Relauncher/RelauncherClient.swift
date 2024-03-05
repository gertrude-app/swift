import AppKit
import Darwin
import Dependencies
import Foundation
import os.log

public struct RelauncherClient: Sendable {
  public var commandLineArgs: @Sendable () -> [String]
  public var fileExistsAtPath: @Sendable (String) -> Bool
  public var openApplication: @Sendable (URL) -> Void
  public var processId: @Sendable () -> pid_t
  public var parentProcessId: @Sendable () -> pid_t
  public var runningApplicationsBundleUrlPaths: @Sendable () -> [String]
  public var sleepForSeconds: @Sendable (Double) -> Void
  public var writeToStdout: @Sendable (String) -> Void
  public var exit: @Sendable (Int32) -> Void

  public init(
    commandLineArgs: @escaping @Sendable () -> [String],
    fileExistsAtPath: @escaping @Sendable (String) -> Bool,
    openApplication: @escaping @Sendable (URL) -> Void,
    processId: @escaping @Sendable () -> pid_t,
    parentProcessId: @escaping @Sendable () -> pid_t,
    runningApplicationsBundleUrlPaths: @escaping @Sendable () -> [String],
    sleepForSeconds: @escaping @Sendable (Double) -> Void,
    writeToStdout: @escaping @Sendable (String) -> Void,
    exit: @escaping @Sendable (Int32) -> Void
  ) {
    self.commandLineArgs = commandLineArgs
    self.fileExistsAtPath = fileExistsAtPath
    self.openApplication = openApplication
    self.processId = processId
    self.parentProcessId = parentProcessId
    self.runningApplicationsBundleUrlPaths = runningApplicationsBundleUrlPaths
    self.sleepForSeconds = sleepForSeconds
    self.writeToStdout = writeToStdout
    self.exit = exit
  }
}

extension RelauncherClient: DependencyKey {
  public static var liveValue: RelauncherClient {
    RelauncherClient(
      commandLineArgs: { CommandLine.arguments() },
      fileExistsAtPath: { FileManager.default.fileExists(atPath: $0) },
      openApplication: { executableUrl in
        NSWorkspace.shared.openApplication(
          at: executableUrl,
          configuration: NSWorkspace.OpenConfiguration()
        )
      },
      processId: { getpid() },
      parentProcessId: { getppid() },
      runningApplicationsBundleUrlPaths: {
        NSWorkspace.shared.runningApplications.compactMap(\.bundleURL?.path)
      },
      sleepForSeconds: { Thread.sleep(forTimeInterval: $0) },
      writeToStdout: { fputs($0, stdout) },
      exit: { Darwin.exit($0) }
    )
  }
}

#if DEBUG
  extension RelauncherClient: TestDependencyKey {
    public static let testValue = RelauncherClient(
      commandLineArgs: { ["/", "Gertrude.app", "--relaunch"] },
      fileExistsAtPath: { _ in true },
      openApplication: { _ in },
      processId: { 1234 },
      parentProcessId: { 5678 },
      runningApplicationsBundleUrlPaths: { [] },
      sleepForSeconds: { _ in },
      writeToStdout: { _ in },
      exit: { _ in }
    )
  }
#endif

// workaround the fact that CommandLine.arguments is not concurrency-safe
// https://github.com/apple/swift/issues/66213#issuecomment-1802037929
public extension CommandLine {
  static func arguments() -> [String] {
    UnsafeBufferPointer(start: unsafeArgv, count: Int(argc)).lazy
      .compactMap { $0 }
      .compactMap { String(validatingUTF8: $0) }
  }
}
