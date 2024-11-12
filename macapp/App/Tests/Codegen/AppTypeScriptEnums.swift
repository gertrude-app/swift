import Foundation
import Gertie
import TypeScriptInterop

@testable import App

struct AppTypeScriptEnums: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    EnumCodableGen.EnumsGenerator(
      name: "MenuBarFeature",
      types: [
        FilterState.WithRelativeTimes.self,
        MenuBarFeature.Action.self,
        MenuBarFeature.State.View.self,
      ]
    ),
    EnumCodableGen.EnumsGenerator(
      name: "BlockedRequestsFeature",
      types: [
        BlockedRequestsFeature.Action.View.self,
      ]
    ),
    EnumCodableGen.EnumsGenerator(
      name: "RequestSuspensionFeature",
      types: [
        RequestSuspensionFeature.Action.View.self,
      ]
    ),
    EnumCodableGen.EnumsGenerator(
      name: "AdminWindowFeature",
      types: [
        AdminWindowFeature.State.HealthCheck.FilterStatus.self,
        AdminWindowFeature.Action.View.AdvancedAction.self,
        AdminWindowFeature.Action.View.self,
      ]
    ),
    EnumCodableGen.EnumsGenerator(
      name: "OnboardingFeature",
      types: [
        OnboardingFeature.Action.View.self,
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

// extensions

extension EnumCodableGen.EnumsGenerator {
  init(name: String, imports: [String: String] = [:], types: [Any.Type]) {
    self.init(
      path:
      "/Users/jared/gertie/swift/macapp/App/Sources/App/Generated/\(name)+Codable.swift",
      types: types.map { ($0, $0 == FilterState.WithRelativeTimes.self) },
      imports: ["ReleaseChannel": "Gertie", "FilterState": "Gertie"]
    )
  }
}
