import ClientInterfaces
import ComposableArchitecture
import Foundation
import os.log

struct EquatableVoid: Equatable {}

extension TaskResult where Success == EquatableVoid {
  init(catching body: @Sendable () async throws -> Void) async {
    do {
      try await body()
      self = .success(EquatableVoid())
    } catch {
      self = .failure(error)
    }
  }
}

extension AnySchedulerOf<DispatchQueue> {
  func schedule(
    after time: DispatchQueue.SchedulerTimeType.Stride,
    action: @escaping () -> Void
  ) {
    schedule(after: now.advanced(by: time), action)
  }
}

public extension _ReducerPrinter {
  static func filteredBy(predicate: @Sendable @escaping (Action) -> Bool)
    -> Self {
    Self { receivedAction, oldState, newState in
      guard predicate(receivedAction) else { return }
      var target = ""
      target.write("received action:\n")
      CustomDump.customDump(receivedAction, to: &target, indent: 2)
      target.write("\n")
      target.write(diff(oldState, newState).map { "\($0)\n" } ?? "  (No state changes)\n")
      print(target)
    }
  }
}

public extension Effect {
  static func exec(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable (Send<Action>) async throws -> Void,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    @Dependency(\.app) var app
    return .run(
      priority: priority,
      operation: operation,
      catch: { error, _ in
        let id = "exec--App_v\(app.installedVersion() ?? "unknown")--\(fileID):\(line)"
        if shouldIgnoreError(error) {
          #if !DEBUG
            os_log("[G•] APP ignoring error `%{public}s` %{public}s", id, "\(error)")
          #endif
          return
        }
        unexpectedError(id: id, error)
      },
      fileID: fileID,
      line: line
    )
  }
}

private func shouldIgnoreError(_ error: Error) -> Bool {
  if let apiError = error as? ApiClient.Error, apiError == .accountInactive {
    return true
  }

  let errorString = String(describing: error)
  let ignoreFrags = ["The network connection was lost.", "The request timed out."]
  for frag in ignoreFrags {
    if errorString.contains(frag) {
      return true
    }
  }

  return false
}
