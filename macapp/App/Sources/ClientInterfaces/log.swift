import Core
import os.log

public func unexpectedError(id: String, _ error: Error? = nil) {
  let detail = error.map { String(describing: $0) }
  os_log("[G•] unexpected error `%{public}s` %{public}s", id, detail ?? "")
  _ = eventReporter.withValue { report in
    Task { await report("unexpected error", id, detail) }
  }
}

public func interestingEvent(id: String, _ detail: String? = nil) {
  os_log("[G•] interesting event `%{public}s` %{public}s", id, detail ?? "")
  _ = eventReporter.withValue { report in
    Task { await report("event", id, detail) }
  }
}

public func setEventReporter(_ reporter: @escaping EventReporter) {
  eventReporter.replace(with: reporter)
}

public typealias EventReporter = @Sendable (String, String, String?) async -> Void
private let eventReporter = Mutex<EventReporter>({ _, _, _ in })
