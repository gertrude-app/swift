import Foundation

@testable import App

struct AppTypeScriptEnums: AggregateCodeGenerator {

  var generators: [CodeGenerator] = [
    TypeScriptEnum(
      name: "MenuBarFeature",
      types: [
        FilterState.self,
        MenuBarFeature.Action.self,
        MenuBarFeature.State.View.self,
      ]
    ),
    TypeScriptEnum(
      name: "BlockedRequestsFeature",
      types: [
        BlockedRequestsFeature.Action.View.self,
      ]
    ),
    TypeScriptEnum(
      name: "RequestSuspensionFeature",
      types: [
        RequestSuspensionFeature.Action.View.self,
      ]
    ),
    TypeScriptEnum(
      name: "AdminWindowFeature",
      types: [
        AdminWindowFeature.State.HealthCheck.FilterStatus.self,
        AdminWindowFeature.Action.View.AdvancedAction.self,
        AdminWindowFeature.Action.View.self,
      ]
    ),
  ]

  func format() throws {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/swiftformat")
    proc.arguments = generators.compactMap { generator in
      (generator as? TypeScriptEnum)?.path
    }
    try proc.run()
  }
}
