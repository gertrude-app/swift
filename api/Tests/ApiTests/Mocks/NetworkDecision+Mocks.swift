import DuetMock
import Foundation

@testable import Api

extension NetworkDecision: Mock {
  public static var mock: NetworkDecision {
    NetworkDecision(deviceId: .init(), verdict: .block, reason: .systemUser, createdAt: Date())
  }

  public static var empty: NetworkDecision {
    NetworkDecision(deviceId: .init(), verdict: .block, reason: .systemUser, createdAt: Date())
  }

  public static var random: NetworkDecision {
    NetworkDecision(
      deviceId: .init(),
      verdict: Verdict.allCases.shuffled().first!,
      reason: Reason.allCases.shuffled().first!,
      createdAt: Date()
    )
  }
}
