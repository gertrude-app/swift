import ArgumentParser
import Foundation
import TypeScript

struct Codegen: AsyncParsableCommand {
  @Argument(help: "`swift` or `typescript`")
  var type: CodeType?

  mutating func run() async throws {
    switch type {
    case .swift:
      try typescript().write()
    case .typescript:
      try swift().write()
    case .none:
      try typescript().write()
      try swift().write()
    }
  }

  func typescript() -> some CodeGenerator {
    AppWebViews()
  }

  func swift() -> some CodeGenerator {
    AppTypeScriptEnums()
  }
}

extension Codegen {
  enum CodeType: String, ExpressibleByArgument {
    case swift
    case typescript
  }
}
