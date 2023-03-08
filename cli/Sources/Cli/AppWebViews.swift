import Foundation
import MenuBar

struct AppWebViews: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    AppviewStore(
      at: "MenuBar/menubar-store.ts",
      generating: [
        .init(MenuBar.State.Connected.FilterState.self),
        .init(MenuBar.State.Screen.self, as: "AppState"),
        .init(MenuBar.Action.self, as: "AppEvent"),
      ],
      aliasing: ["filterState": "FilterState"]
    ),
  ]

  func format() throws {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/make")
    proc.currentDirectoryURL = URL(fileURLWithPath: "/Users/jared/gertie/web")
    proc.arguments = ["format-codegen"]
    try proc.run()
  }
}
