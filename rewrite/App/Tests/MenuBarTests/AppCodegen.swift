import TypeScript
import XCTest

@testable import MenuBar

final class AppCodegen: XCTestCase {
  func testSwiftCodegen_MenuBar() throws {
    try codableCodegen(module: "MenuBar", types: [
      MenuBar.State.Connected.FilterState.self,
      MenuBar.State.Screen.self,
    ])
  }

  func testTypeScriptCodegen_MenuBar() throws {
    guard runningCodegen else { return }
    let ts = CodeGen(config: .init(compact: true, aliasing: ["filterState": "FilterState"]))

    try tsCodegen(file: "MenuBar/menubar-store.ts", decls: [
      try ts.declaration(for: MenuBar.State.Connected.FilterState.self),
      try ts.declaration(for: MenuBar.State.Screen.self, as: "AppState"),
      try ts.declaration(for: MenuBar.Action.self, as: "AppEvent"),
    ])
  }
}

// helpers

extension AppCodegen {
  func codableCodegen(module: String, types: [Any.Type]) throws {
    let codableUrl = URL(fileURLWithPath: "Sources/\(module)/\(module)+Codable.swift")
    let header = "// auto-generated, do not edit\nimport TypeScript\n\n"
    let decls = try types.map { try EnumType(from: $0).codableConformance }
    let file = header + decls.joined(separator: "\n\n")
    try file.data(using: .utf8)!.write(to: codableUrl)
  }

  func tsCodegen(file: String, decls: [String]) throws {
    let appviewsDir = "\(env(var: "CODEGEN_WEB_DIR")!)/appviews/src"
    let storeUrl = URL(fileURLWithPath: "\(appviewsDir)/\(file)")
    let storeFile = String(data: try Data(contentsOf: storeUrl), encoding: .utf8)!
    let lines = storeFile.components(separatedBy: "\n")

    var updatedLines: [String] = []
    var inCodegen = false
    for line in lines {
      if line == "// begin codegen" {
        inCodegen = true
        updatedLines.append(line)
        updatedLines.append(decls.joined(separator: "\n\n"))
      } else if line.contains("// end codegen") {
        inCodegen = false
        updatedLines.append(line)
      } else if !inCodegen {
        updatedLines.append(line)
      }
    }

    try updatedLines.joined(separator: "\n").data(using: .utf8)?
      .write(to: storeUrl)
    try prettier()
  }

  func prettier() throws {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/make")
    proc.currentDirectoryURL = URL(fileURLWithPath: env(var: "CODEGEN_WEB_DIR")!)
    proc.arguments = ["format-codegen"]
    try proc.run()
  }

  func env(`var`: String) -> String? {
    ProcessInfo.processInfo.environment[`var`]
  }

  var runningCodegen: Bool {
    env(var: "CODEGEN_APPVIEWS") == "true"
  }
}
