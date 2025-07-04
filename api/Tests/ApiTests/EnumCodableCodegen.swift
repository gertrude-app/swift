import Foundation
import Gertie
import GertieIOS
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
        (Parent.NotificationMethod.Config.self, false),
        (DecideFilterSuspensionRequest.Decision.self, false),
        (GetAdmin.SubscriptionStatus.self, false),
        (SecurityEventsFeed.FeedEvent.self, false),
        (UserActivity.Item.self, true),
        (ChildComputerStatus.self, false),
        (GertieIOS.BlockRule.self, false),
      ],
      imports: [
        "Tagged": "Tagged",
        "BlockRule": "GertieIOS",
      ],
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
