import Foundation
import Gertie

@testable import Api

extension NetworkDecision: RandomMocked {
  public static var mock: NetworkDecision {
    NetworkDecision(userDeviceId: .init(), verdict: .block, reason: .systemUser, createdAt: Date())
  }

  public static var empty: NetworkDecision {
    NetworkDecision(userDeviceId: .init(), verdict: .block, reason: .systemUser, createdAt: Date())
  }

  public static var random: NetworkDecision {
    NetworkDecision(
      userDeviceId: .init(),
      verdict: NetworkDecisionVerdict.allCases.shuffled().first!,
      reason: NetworkDecisionReason.allCases.shuffled().first!,
      createdAt: Date()
    )
  }
}
