import PairQL
import Vapor

extension Response {
  convenience init(_ error: PqlError) {
    self.init(
      status: .init(statusCode: error.statusCode),
      body: .init(data: (try? JSONEncoder().encode(error)) ?? .init()),
    )
  }
}
