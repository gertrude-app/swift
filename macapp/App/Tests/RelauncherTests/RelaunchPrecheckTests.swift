import ComposableArchitecture
import TestSupport
import XCTest
import XExpect

@testable import Relauncher

final class RelaunchPrecheckTests: XCTestCase {
  func testRelaunchPrecheck_HappyPath() {
    let (client, invocations) = recordingClient(args: ["/", "Gertrude.app", "--precheck"])

    Relauncher.run(client)

    expect(invocations.value).toEqual([
      .parentProcessId,
      .processId,
      .commandLineArgs,
      .fileExistsAtPath("Gertrude.app"),
      .writeToStdout("OK"),
      .exit(0),
    ])
  }

  func testUnreachableAppUrlTriggersEarlyExitFail() {
    let (client, invocations) = recordingClient(
      args: ["/", "Gertrude.app", "--precheck"],
      fileExistsAtPath: false
    )

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
}
