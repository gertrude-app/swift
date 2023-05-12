import Dependencies
import Foundation

struct MonitoringClient: Sendable {
  var takeScreenshot: @Sendable (Int) async throws -> (data: Data, width: Int, height: Int)?
}

extension MonitoringClient: DependencyKey {
  static let liveValue = Self(
    takeScreenshot: takeScreenshot(width:)
  )
}

extension MonitoringClient: TestDependencyKey {
  static let testValue = Self(
    takeScreenshot: { _ in (data: .init(), width: 900, height: 600) }
  )
}

extension DependencyValues {
  var monitoring: MonitoringClient {
    get { self[MonitoringClient.self] }
    set { self[MonitoringClient.self] = newValue }
  }
}
