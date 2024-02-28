import ComposableArchitecture
import TestSupport
import XCTest
import XExpect

@testable import Relauncher

final class RelaunchCrashRestart: XCTestCase {
  func testCrashRestart_RestartsOnCrash() {
    let (client, invocations) = recordingClient(
      args: ["/", "Gertrude.app", "--crash-watch"],
      parentProcessIds: [99, 99, 99, 1]
    )

    Relauncher.run(client)

    expect(invocations.value).toEqual([
      .parentProcessId, // the first 99
      .processId,
      .commandLineArgs,
      .fileExistsAtPath("Gertrude.app"),
      .sleepForSeconds(5.0),
      .parentProcessId, // they see the second 99
      .sleepForSeconds(5.0),
      .parentProcessId, // they see the third 99
      .sleepForSeconds(5.0),
      .parentProcessId, // now they see `1`, so relaunch
      .openApplication(URL(string: "Gertrude.app")!),
      // then sleep a bit and terminate self
      .sleepForSeconds(0.2),
      .exit(0),
    ])
  }

  func testUnexpectedSubcommandFails() {
    let (client, invocations) = recordingClient(args: [
      "/",
      "Gertrude.app",
      "--nope-bad", // <-- unexpected subcommand
    ])

    Relauncher.run(client)

    expect(invocations.value).toEqual([
      .parentProcessId,
      .processId,
      .commandLineArgs,
      .fileExistsAtPath("Gertrude.app"),
      .writeToStdout("FAIL"),
      .exit(1),
    ])
  }
}
