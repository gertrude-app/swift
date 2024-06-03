import Foundation
import Gertie
import TypeScriptInterop
import XCTest

@testable import Api

final class Codegen: XCTestCase {
  func test_codegenSwift() throws {
    if self.envVarSet("CODEGEN_SWIFT") {
      try ApiTypeScriptEnumsCodableGenerator().write()
    }
  }

  func envVarSet(_ name: String) -> Bool {
    ProcessInfo.processInfo.environment[name] != nil
  }
}

struct ApiTypeScriptEnumsCodableGenerator: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    EnumCodableGen.EnumsGenerator(
      path: "/Users/jared/gertie/swift/api/Sources/Api/Extend/Enums+Codable.swift",
      types: [
        (AdminVerifiedNotificationMethod.Config.self, false),
        (DecideFilterSuspensionRequest.Decision.self, false),
        (GetAdmin.SubscriptionStatus.self, false),
        (UserActivity.Item.self, true),
      ],
      imports: ["Tagged": "Tagged"],
      replacements: [
        "Foundation.UUID": "UUID",
        "Tagged.Tagged": "Tagged",
      ]
    ),
  ]

  func format() throws {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/swiftformat")
    proc.arguments = self.generators.compactMap { generator in
      (generator as? EnumCodableGen.EnumsGenerator)?.path
    }
    try proc.run()
  }
}
