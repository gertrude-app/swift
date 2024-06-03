import XCTest

@testable import App

final class Codegen: XCTestCase {
  func test_codegenSwift() throws {
    if self.envVarSet("CODEGEN_SWIFT") {
      try AppTypeScriptEnums().write()
    }
  }

  func test_codegenTypescript() throws {
    if self.envVarSet("CODEGEN_TYPESCRIPT") {
      try AppWebViews().write()
    }
  }

  func envVarSet(_ name: String) -> Bool {
    ProcessInfo.processInfo.environment[name] != nil
  }
}
