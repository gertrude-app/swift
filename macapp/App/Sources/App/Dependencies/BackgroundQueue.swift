import Dependencies
import Foundation

extension DependencyValues {
  var backgroundQueue: AnySchedulerOf<DispatchQueue> {
    get { self[BackgroundQueueKey.self] }
    set { self[BackgroundQueueKey.self] = newValue }
  }

  private enum BackgroundQueueKey: DependencyKey {
    static let liveValue = AnySchedulerOf<DispatchQueue>.global(qos: .background)
    static let testValue = AnySchedulerOf<DispatchQueue>
      .unimplemented(#"@Dependency(\.BackgroundQueue)"#)
  }
}
