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
  }
}
