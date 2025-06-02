import Foundation

enum ChildComputerStatus: Equatable, Sendable, Codable {
  case offline
  case filterOff
  case filterOn
  // NB: dates optional while still supporting < `v2.7.0`
  case filterSuspended(resuming: Date?)
  case downtime(ending: Date?)
  case downtimePaused(resuming: Date?)
}

extension ChildComputerStatus {
  var isSuspended: Bool {
    if case .filterSuspended = self {
      return true
    }
    return false
  }

  var isDowntimePaused: Bool {
    if case .downtimePaused = self {
      return true
    }
    return false
  }

  var isDowntime: Bool {
    if case .downtime = self {
      return true
    }
    return false
  }
}

func consolidatedChildComputerStatus(
  _ userId: User.Id,
  _ computerUsers: [ComputerUser]
) async throws -> ChildComputerStatus {
  let statuses = try await computerUsers
    .filter { $0.childId == userId }
    .concurrentMap { await $0.status() }
  if statuses.isEmpty {
    return .offline
  } else if statuses.count == 1 {
    return statuses[0]
  } else if statuses.allSatisfy({ $0 == statuses[0] }) {
    return statuses[0]
  }

  // if we happen to have more than two child computers online
  // reporting _different_ things, return the "scariest" one
  return statuses.first(where: { $0 == .filterOff })
    ?? statuses.first(where: { $0.isSuspended })
    ?? statuses.first(where: { $0.isDowntimePaused })
    ?? statuses.first(where: { $0.isDowntime })
    ?? statuses[0]
}
