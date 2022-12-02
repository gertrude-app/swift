import Foundation

// input, response

protocol Test2 {
  associatedtype Input: Codable
  associatedtype Output: Codable
}

struct Rofl2: Test2 {
  struct Input: Codable {
    let name: String
  }

  struct Output: Codable {
    let name: String
  }
}

protocol Test1 {
  static var operation: Codable.Type { get }
}

struct Rofl: Test1 {
  struct Hi: Codable {
    let name: String
  }

  static var operation: Codable.Type {
    [Hi].self
  }
}

// contract: string operation name, codable input, codable response

//

enum Wrapper {
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

  enum Jared {
    case rofl(Codable)
    case lol(Codable.Type)
  }

  struct GertieQLError: Error {}

  enum GertieQLResult<Data: Codable> {
    case success(Data)
    case error(GertieQLError)
  }

  func anotherFunc(input: GetUserName.Input) async throws -> GetUserName.Data {
    fatalError()
  }

  func myFunc() async throws -> Any {
    let body = """
    {
      "operation": "getAdmin123",
      "input": {
          "userId": "123"
        }
      }
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
}
