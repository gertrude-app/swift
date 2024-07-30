import DuetSQL
import MacAppRoute
import XCore
import XCTest
import XExpect

@testable import Api

final class LogInterestingEventResolverTests: ApiTestCase {
  func testNonSearchableIdDoesntSlackUselessCodeLink() async throws {
    let input = LogInterestingEvent.Input(
      // dynamically assembled event id, not searchable in github
      eventId: "exec--App_v2.3.2--App/MonitoringFeature.swift:59",
      kind: "unexpected error",
      deviceId: nil,
      detail: nil
    )

    _ = try await LogInterestingEvent.resolve(with: input, in: .mock)

    expect(sent.slacks).toHaveCount(1)
    expect(sent.slacks[0].0.text).not.toContain("github.com/search")
  }

  func testSearchableIdSlacksCodeSearchLink() async throws {
    let input = LogInterestingEvent.Input(
      eventId: "a9fde6b3",
      kind: "unexpected error",
      deviceId: nil,
      detail: nil
    )

    _ = try await LogInterestingEvent.resolve(with: input, in: .mock)

    expect(sent.slacks).toHaveCount(1)
    expect(sent.slacks[0].0.text).toContain("github.com/search")
  }

  func testShortensVerboseNSUrlErrors() async throws {
    let errors =
      [
        "Error Domain=NSURLErrorDomain Code=-1200 \"An SSL error has occurred and a secure connection to the server cannot be made.\" UserInfo={NSErrorFailingURLStringKey=https://gertrude.nyc3.foo": "SSL Error =-1200 (spaces)",
        "Error Domain=NSURLErrorDomain Code=-1200 \"An SSL error has occurred and a secure connection to the server cannot be made.\" UserInfo={NSErrorFailingURLStringKey=https://api.gertrude.app/fake": "SSL Error =-1200 (API)",
        "Error Domain=NSURLErrorDomain Code=-1004 \"Could not connect to the server.\" UserInfo={_kCFStreamErrorCodeKey=61, NSUnderlyingError=0x6000037052c0StringKey=https://gertrude.nyc3.digita": "Failed to Connect Error =-1004 (spaces)",
        "Error Domain=NSURLErrorDomain Code=-1004 \"Could not connect to the server.\" UserInfo={_kCFStreamErrorCodeKey=61, NSUnderlyingError=0x6000037052c0StringKey=https://api.gertrude.app/foo": "Failed to Connect Error =-1004 (API)",
        "Error Domain=NSURLErrorDomain Code=-1017 \"cannot parse response\" UserInfo={_kCFStreamErrorCodeKey=-1, NSUnderlyingError=0x600001afa910StringKey=https://gertrude.nyc3.digita": "Parse Response Error =-1017 (spaces)",
        "Error Domain=NSURLErrorDomain Code=-1017 \"cannot parse response\" UserInfo={_kCFStreamErrorCodeKey=-1, NSUnderlyingError=0x600001afa91StringKey=https://api.gertrude.app/foo": "Parse Response Error =-1017 (API)",
      ]

    for (i, (detail, expected)) in errors.enumerated() {
      let input = LogInterestingEvent.Input(
        eventId: "a9fde6b3",
        kind: "unexpected error",
        deviceId: nil,
        detail: detail
      )

      _ = try await LogInterestingEvent.resolve(with: input, in: .mock)

      expect(sent.slacks).toHaveCount(i + 1)
      expect(sent.slacks[i].0.text).not.toContain(detail)
      expect(sent.slacks[i].0.text).toContain(expected)
    }
  }
}
