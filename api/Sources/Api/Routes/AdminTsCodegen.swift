import Gertie
import PairQL
import Tagged
import TypeScriptInterop
import Vapor

enum AdminTsCodegenRoute {
  struct Response: Content {
    var pairs: [String: String]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      AnalyticsOverview.self,
      ParentOverviews.self,
    ]
  }

  @Sendable static func handler(_ request: Request) async throws -> Response {
    let sharedAliases: [Config.Alias] = [
      .init(NoInput.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
    ]
    let config = Config(compact: true, aliasing: sharedAliases)

    var pairs: [String: String] = [:]
    for pairType in self.pairqlPairs {
      pairs[pairType.name] = try self.ts(for: pairType, with: config)
    }

    return Response(pairs: pairs)
  }

  private static func ts<P: Pair>(
    for type: P.Type,
    with config: Config
  ) throws -> String {
    let codegen = CodeGen(config: config)
    let name = "\(P.self)"
    var pair = try """
    export namespace \(name) {
      \(codegen.declaration(for: P.Input.self, as: "Input"))

      \(codegen.declaration(for: P.Output.self, as: "Output"))
    }
    """

    // pairs that are only typealiases get compacted more
    let pairLines = pair.split(separator: "\n")
    if pairLines.count == 4, pairLines.allSatisfy({ $0.count < 60 }) {
      pair = pairLines.joined(separator: "\n")
    }

    return pair
  }
}
