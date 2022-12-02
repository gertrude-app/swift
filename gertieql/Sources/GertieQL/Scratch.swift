import Foundation

public func getPair(_ route: GertieQL.Route) async throws -> AnyPair<String> {
  switch route {
  case .dashboard(let dashboard):
    switch dashboard {
    case .placeholder:
      fatalError("placeholder")
    }
  case .macApp(let macApp):
    switch macApp {
    case .userTokenAuthed(let uuid, let userTokenAuthed):
      print("userTokenAuthed \(uuid)")
      switch userTokenAuthed {
      case .createSignedScreenshotUpload(let input):
        let pair = LolPair(input: input, resolve: Resolver.rofl)
        return AnyPair(pair: pair, transform: { output, _ in
          .init(foo: output.foo)
        })
      case .getUsersAdminAccountStatus:
        fatalError("getUsersAdminAccountStatus")
      }
    case .unauthed(let unAuthed):
      print("unauthed")
      switch unAuthed {
      case .register:
        fatalError("register")
      }
    }
  }
}

enum Resolver {
  static func rofl(input: LolPair.Input, context: String) async throws -> LolPair.Output {
    .init(foo: "did it")
  }

  static func wrong(_ input: LolPair.Input, _ context: String) async throws -> String {
    "lo"
  }
}

// old...

enum Wrapper {
  func myFunc() async throws -> Any {
    let body = """
    {
      "operation": "getAdmin123",
      "input": { "userId": "123" } }
    }
    """

    let opInput = try JSONDecoder().decode(NamedOperation.self, from: body.data(using: .utf8)!)
    switch Operation(rawValue: opInput.operation) {
    case .getUserName:
      let input = try JSONDecoder()
        .decode(Input<GetUserName.Input>.self, from: body.data(using: .utf8)!)
        .input
      let result = try await anotherFunc(input: input)
      return result
    case .none:
      fatalError("Unknown operation: \(opInput.operation)")
    }
  }

  enum Operation: String, Codable {
    case getUserName
  }

  struct NamedOperation: Codable {
    var operation: String
  }

  struct Input<T: Codable>: Codable {
    var input: T
  }

  enum GetUserName {
    struct Input: Codable {
      var userId: UUID
    }

    struct Data: Codable {
      var userName: String
    }
  }

  func anotherFunc(input: GetUserName.Input) async throws -> GetUserName.Data {
    fatalError()
  }
}
