import DuetMock
import Foundation
import Gertie

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
      verdict: NetworkDecisionVerdict.allCases.shuffled().first!,
      reason: NetworkDecisionReason.allCases.shuffled().first!,
      createdAt: Date()
    )
  }
}
