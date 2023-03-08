import Foundation
import MenuBar

struct AppTypeScriptEnums: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    TypeScriptEnum(module: "MenuBar", types: [
      MenuBar.State.Connected.FilterState.self,
      MenuBar.State.Screen.self,
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
