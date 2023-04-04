import Dependencies
import Foundation
import Models
import XExpect

func expect<T: Equatable>(
  _ isolated: ActorIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line
) async -> EquatableExpectation<T> {
  EquatableExpectation(value: await isolated.value, file: file, line: line)
}

func expect<T: Equatable>(
  _ isolated: LockIsolated<T>,
  file: StaticString = #filePath,
  line: UInt = #line
) -> EquatableExpectation<T> {
  EquatableExpectation(value: isolated.value, file: file, line: line)
}

struct TestErr: Equatable, Error, LocalizedError {
  let msg: String
  var errorDescription: String? { msg }
  init(_ msg: String) { self.msg = msg }
}

extension User {
  static let mock = User(
    id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
    token: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
    deviceId: .init(uuidString: "00000000-0000-0000-0000-000000000000")!,
    name: "Huck",
    keyloggingEnabled: true,
    screenshotsEnabled: true,
    screenshotFrequency: 1,
    screenshotSize: 1,
    connectedAt: .init(timeIntervalSince1970: 0)
  )
}
