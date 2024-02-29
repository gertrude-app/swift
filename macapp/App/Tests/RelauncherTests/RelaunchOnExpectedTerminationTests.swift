import ComposableArchitecture
import TestSupport
import XCTest
import XExpect

@testable import Relauncher

final class RelaunchOnExpectedTerminationTests: XCTestCase {
  func testRelaunchOnExpectedTermination_HappyPath() {
    let (client, invocations) = recordingClient(parentProcessIds: [99, 99, 99, 1])

    Relauncher.run(client)

    expect(invocations.value).toEqual([
      .parentProcessId, // the first 99
      .processId,
      .commandLineArgs,
      .fileExistsAtPath("Gertrude.app"),
      .sleepForSeconds(0.2),
      .parentProcessId, // they see the second 99
      .sleepForSeconds(0.2),
      .parentProcessId, // they see the third 99
      .sleepForSeconds(0.2),
      .parentProcessId, // now they see `1`, so relaunch
      .runningApplications,
      .openApplication(URL(string: "Gertrude.app")!),
      // then sleep a bit and terminate self
      .sleepForSeconds(0.2),
      .exit(0),
    ])
  }

  func testWeirdCommandLineArgsTriggersEarlyFailedExit() {
    let (client, invocations) = recordingClient(args: ["not", "enough"])

    Relauncher.run(client)

    expect(invocations.value).toEqual([
      .parentProcessId,
      .processId,
      .commandLineArgs, // <-- wrong number, so...
      .writeToStdout("FAIL"),
      .exit(1),
    ])
  }

  func testUnreachableAppUrlTriggersEarlyExitFail() {
    let (client, invocations) = recordingClient(fileExistsAtPath: false)

    Relauncher.run(client)

    expect(invocations.value).toEqual([
      .parentProcessId,
      .processId,
      .commandLineArgs,
      .fileExistsAtPath("Gertrude.app"), // <-- doesn't exist, so...
      .writeToStdout("FAIL"),
      .exit(1),
    ])
  }

  func testRelaunchOnExpectedTermination_GivesUpIfAppNeverTerminates() {
    let ppids = Array(repeating: Int32(99), count: 200)
    let (client, invocations) = recordingClient(parentProcessIds: ppids)

    Relauncher.run(client)

    var expected: [RelaunchClientInvocation] = [
      .parentProcessId,
      .processId,
      .commandLineArgs,
      .fileExistsAtPath("Gertrude.app"),
    ]
    for _ in 0 ..< 100 {
      expected.append(contentsOf: [
        .sleepForSeconds(0.2),
        .parentProcessId,
      ])
    }
    expected.append(contentsOf: [
      .writeToStdout("FAIL"),
      .exit(1),
    ])

    expect(invocations.value).toEqual(expected)

    let totalTimeSlept = invocations.value.reduce(0.0) { total, invocation in
      switch invocation {
      case .sleepForSeconds(let seconds): return total + seconds
      default: return total
      }
    }
    // we quit at around 20 seconds
    expect(Int(ceil(totalTimeSlept))).toEqual(20)
  }
}

// helpers

enum RelaunchClientInvocation: Equatable, Sendable {
  case commandLineArgs
  case fileExistsAtPath(String)
  case sleepForSeconds(Double)
  case openApplication(URL)
  case processId
  case parentProcessId
  case runningApplications
  case writeToStdout(String)
  case exit(Int32)
}

func recordingClient(
  args: [String] = ["/", "Gertrude.app", "--relaunch"],
  fileExistsAtPath: Bool = true,
  runningApps: [String] = [],
  processId: pid_t = 1234,
  parentProcessIds: [pid_t] = [5678]
) -> (RelauncherClient, LockIsolated<[RelaunchClientInvocation]>) {
  let invocations = LockIsolated<[RelaunchClientInvocation]>([])
  let ppids = LockIsolated(parentProcessIds)
  let client = RelauncherClient(
    commandLineArgs: {
      invocations.append(.commandLineArgs)
      return args
    },
    fileExistsAtPath: { path in
      invocations.append(.fileExistsAtPath(path))
      return fileExistsAtPath
    },
    openApplication: { url in
      invocations.append(.openApplication(url))
    },
    processId: {
      invocations.append(.processId)
      return processId
    },
    parentProcessId: {
      invocations.append(.parentProcessId)
      return ppids.withValue { ppids in
        ppids.count == 1 ? ppids[0] : ppids.removeFirst()
      }
    },
    runningApplicationsBundleUrlPaths: {
      invocations.append(.runningApplications)
      return runningApps
    },
    sleepForSeconds: { seconds in
      invocations.append(.sleepForSeconds(seconds))
    },
    writeToStdout: { string in
      invocations.append(.writeToStdout(string))
    },
    exit: { status in
      invocations.append(.exit(status))
    }
  )
  return (client, invocations)
}
