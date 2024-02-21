import Foundation

enum MacOSUserType: String, Codable {
  case admin
  case standard
}

struct MacOSUser: Hashable, Codable, Equatable {
  var id: uid_t
  var name: String
  var type: MacOSUserType
}

extension DeviceClient {
  func nonCurrentUsers() async throws -> [MacOSUser] {
    try await listMacOSUsers().filter { $0.id != currentUserId() }
  }
}

@Sendable func getCurrentMacOSUserType() async throws -> MacOSUserType {
  try await userIsAdmin(getuid()) ? .admin : .standard
}

// @see https://stackoverflow.com/questions/3681895/get-all-users-on-os-x
@Sendable func getAllMacOSUsers() async throws -> [MacOSUser] {
  let defaultAuthority = CSGetLocalIdentityAuthority().takeUnretainedValue()
  let identityClass = kCSIdentityClassUser
  let query = CSIdentityQueryCreate(nil, identityClass, defaultAuthority).takeRetainedValue()
  var error: Unmanaged<CFError>?
  CSIdentityQueryExecute(query, 0, &error)
  let results = CSIdentityQueryCopyResults(query).takeRetainedValue()
  let resultsCount = CFArrayGetCount(results)
  var users: Set<MacOSUser> = []

  for idx in 0 ..< resultsCount {
    let identity = unsafeBitCast(CFArrayGetValueAtIndex(results, idx), to: CSIdentity.self)
    let id: uid_t = CSIdentityGetPosixID(identity)
    let name = CSIdentityGetFullName(identity).takeUnretainedValue() as String
    let type = try await userIsAdmin(id) ? MacOSUserType.admin : .standard
    users.insert(.init(id: id, name: name, type: type))
  }

  return Array(users)
}

@Sendable func userIsAdmin(_ userId: uid_t) async throws -> Bool {
  enum GetUserTypeError: Error {
    case stringDecodeError
    case other(Error)
  }
  let task = Task {
    do {
      let proc = Process()
      let pipe = Pipe()
      proc.executableURL = URL(fileURLWithPath: "/usr/bin/id")
      proc.arguments = ["\(userId)"]
      proc.standardOutput = pipe
      try proc.run()
      proc.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let string = String(data: data, encoding: .utf8) {
        return string.contains("(admin)") ? true : false
      } else {
        throw GetUserTypeError.stringDecodeError
      }
    } catch {
      throw GetUserTypeError.other(error)
    }
  }
  return try await task.value
}
