import App
import Foundation

struct AppTypeScriptEnums: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    TypeScriptEnum(name: "MenuBar", types: [
      MenuBar.Action.self,
      MenuBar.State.Connected.FilterState.self,
      MenuBar.State.self,
    ]),
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
