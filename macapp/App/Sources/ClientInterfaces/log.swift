import Core
import os.log

public func unexpectedError(id: String, _ error: Error? = nil) {
  os_log(
    "[G•] unexpected error %{public}s %{public}s",
    id,
    error.map { String(describing: $0) } ?? ""
  )
  _ = errorReporter.withValue { report in Task { await report(id, error) } }
}

public func setUnexpectedErrorReporter(_ reporter: @escaping UnexpectedErrorReporter) {
  errorReporter.replace(with: reporter)
}

public typealias UnexpectedErrorReporter = @Sendable (String, Error?) async -> Void
private let errorReporter = Mutex<UnexpectedErrorReporter>({ _, _ in })
