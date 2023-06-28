import Foundation
import TypeScriptInterop
import XCTest

@testable import Api

final class Codegen: XCTestCase {
  func test_codegenSwift() throws {
    if ProcessInfo.processInfo.environment["CODEGEN_SWIFT"] != nil {
      try ApiTypeScriptEnumsCodableGenerator().write()
    }
  }
}

struct ApiTypeScriptEnumsCodableGenerator: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    EnumCodableGen.EnumsGenerator(
      path: "/Users/jared/gertie/swift/api/Sources/Api/Extend/Enums+Codable.swift",
      types: [
        (AdminVerifiedNotificationMethod.Config.self, false),
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
    proc.arguments = generators.compactMap { generator in
      (generator as? EnumCodableGen.EnumsGenerator)?.path
    }
    try proc.run()
  }
}
