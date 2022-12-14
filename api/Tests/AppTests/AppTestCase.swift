import DuetSQL
import Vapor
import XCTest

@testable import App

class AppTestCase: XCTestCase {
  static var app: Application!

  var app: Application {
    Self.app
  }

  override static func setUp() {
    Current = .mock
    app = Application(.testing)
    try! Configure.app(app)
    try! app.autoRevert().wait()
    try! app.autoMigrate().wait()
  }

  override static func tearDown() {
    app.shutdown()
    sync { await SQL.resetPreparedStatements() }
  }
}

func sync(
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column,
  _ f: @escaping () async throws -> Void
) {
  let exp = XCTestExpectation(description: "sync:\(function):\(line):\(column)")
  Task {
    do {
      try await f()
      exp.fulfill()
    } catch {
      fatalError("Error awaiting \(exp.description) -- \(error)")
    }
  }
  switch XCTWaiter.wait(for: [exp], timeout: 10) {
  case .completed:
    return
  case .timedOut:
    fatalError("Timed out waiting for \(exp.description)")
  default:
    fatalError("Unexpected result waiting for \(exp.description)")
  }
}
