import Foundation

@Sendable func getCurrentMacOsUserType() async throws -> MacOsUserType {
  enum GetUserTypeError: Error {
    case stringDecodeError
    case other(Error)
  }
  let task = Task {
    do {
      let proc = Process()
      let pipe = Pipe()
      proc.executableURL = URL(fileURLWithPath: "/usr/bin/id")
      proc.arguments = ["\(getuid())"]
      proc.standardOutput = pipe
      try proc.run()
      proc.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let string = String(data: data, encoding: String.Encoding.utf8) {
        return string.contains("(admin)") ? MacOsUserType.admin : .standard
      } else {
        throw GetUserTypeError.stringDecodeError
      }
    } catch {
      throw GetUserTypeError.other(error)
    }
  }
  return try await task.value
}
